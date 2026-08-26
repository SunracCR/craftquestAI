import 'dart:async';

import 'package:craftquest_app/core/billing/ios_store_unfinished_transactions.dart';
import 'package:craftquest_app/core/billing/mobile_store_purchase_completion.dart';
import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';
import 'package:craftquest_app/core/billing/pending_store_purchase_store.dart';
import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Orquestador central de compras IAP: un solo listener, máquina de estados,
/// watchdog, manejo de pending y recuperación en background.
class PurchaseOrchestrator extends ChangeNotifier {
  PurchaseOrchestrator({
    required PendingStorePurchaseStore pendingStore,
    BillingRepository? billingRepository,
    PrepPlusRepository? prepPlusRepository,
  })  : _pendingStore = pendingStore,
        _billingRepository = billingRepository ?? getIt<BillingRepository>(),
        _prepPlusRepository = prepPlusRepository ?? getIt<PrepPlusRepository>();

  static const _restoreThrottle = Duration(seconds: 30);
  static const _watchdogDuration = Duration(seconds: 90);
  static const _inFlightTtl = Duration(minutes: 5);
  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';

  final PendingStorePurchaseStore _pendingStore;
  final BillingRepository _billingRepository;
  final PrepPlusRepository _prepPlusRepository;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Timer? _watchdogTimer;
  bool _started = false;
  bool _inFlight = false;
  DateTime? _lastRestoreAt;
  StorePurchaseRequest? _activeRequest;

  PurchaseFlowState _state = const PurchaseIdle();
  PurchaseFlowState get state => _state;

  bool get isBusy =>
      _state is PurchasePreparing ||
      _state is PurchaseAwaitingStore ||
      _state is PurchaseVerifying;

  /// True solo cuando ya se lanzó la compra real del usuario (tras la
  /// reconciliación previa) y estamos esperando el evento genuino del
  /// purchaseStream para esa compra. Antes de este punto (p. ej. durante la
  /// reconciliación de transacciones atascadas previa al lanzamiento), los
  /// eventos entrantes del stream deben tratarse como background aunque
  /// `_inFlight`/`_activeRequest` ya estén asignados.
  bool get _isAwaitingActivePurchaseResponse =>
      _inFlight &&
      _activeRequest != null &&
      (_state is PurchaseAwaitingStore || _state is PurchaseVerifying);

  final Set<String> _completedPurchaseKeys = {};
  final Map<String, DateTime> _inFlightPurchaseKeys = {};

  Set<String> _aiCreditProductIds = {};
  Set<String> _subscriptionProductIds = {};
  Map<String, PrepMobileStoreProductModel> _prepProducts = {};
  List<UpgradeablePlanModel> _plans = [];

  static bool get supportsStore =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool isAiCreditProduct(String productId) => _isAiCreditProduct(productId);

  bool isSubscriptionProduct(String productId) =>
      _isSubscriptionProduct(productId);

  bool isPrepProduct(String productId) => _isPrepProduct(productId);

  String billingCycleForProduct(String productId) =>
      _billingCycleForProduct(productId);

  Future<void> refreshStoreCatalog() => _refreshProductCatalog();

  Future<void> start() async {
    if (!supportsStore || _started) {
      return;
    }
    _started = true;
    await _refreshProductCatalog();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen((purchases) {
      unawaited(
        _onPurchaseUpdate(
          purchases,
          background: !_isAwaitingActivePurchaseResponse,
        ),
      );
    });
    await _reconcileUnfinishedStoreTransactions(background: true);
    await _restorePurchases(force: true);
    await _reconcilePendingIntent();
  }

  void stop() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _purchaseSub?.cancel();
    _purchaseSub = null;
    _started = false;
    _inFlight = false;
    _activeRequest = null;
    _completedPurchaseKeys.clear();
    _inFlightPurchaseKeys.clear();
    _lastRestoreAt = null;
    _setState(const PurchaseIdle());
  }

  Future<void> onAppResume() async {
    if (!_started) {
      return;
    }
    _expireStaleInFlightKeys();
    await _refreshProductCatalog();
    await _reconcileUnfinishedStoreTransactions(background: true);
    await _restorePurchases();
    await _reconcilePendingIntent();
  }

  /// Inicia una compra en tienda. Retorna el resultado o null si falló/canceló.
  Future<PurchaseFlowResult?> buy(StorePurchaseRequest request) async {
    if (!supportsStore) {
      _setState(const PurchaseFailed(PurchaseFailureReason.storeUnavailable));
      return null;
    }

    if (_inFlight) {
      _setState(const PurchaseFailed(PurchaseFailureReason.duplicateInFlight));
      return null;
    }

    _inFlight = true;
    _activeRequest = request;
    _setState(const PurchasePreparing());

    try {
      if (!await isMobileStoreAvailable()) {
        _fail(PurchaseFailureReason.storeUnavailable);
        return null;
      }

      ProductDetails? product = request.product;
      final normalizedProductId = normalizeStoreProductId(request.productId);
      product ??= await findMobileStoreProduct(normalizedProductId);
      if (product == null) {
        _fail(PurchaseFailureReason.productNotFound);
        return null;
      }

      await _pendingStore.save(
        PendingStorePurchase(
          kind: request.kind,
          productId: product.id,
          createdAt: DateTime.now().toUtc(),
          billingCycle: request.billingCycle,
          catalogItemId: request.catalogItemId,
          offerId: request.offerId,
          referralCode: request.referralCode,
        ),
      );

      await _reconcileUnfinishedStoreTransactions(
        productId: product.id,
        background: true,
      );
      if (_state is PurchaseSucceeded) {
        return (_state as PurchaseSucceeded).result;
      }

      _setState(const PurchaseAwaitingStore());
      _startWatchdog();

      final param = PurchaseParam(productDetails: product);
      final launched = await _launchStorePurchase(
        request: request,
        param: param,
      );
      if (!launched) {
        return null;
      }
      if (_state is PurchaseSucceeded) {
        return (_state as PurchaseSucceeded).result;
      }

      // El resultado llega vía purchaseStream; el caller espera el estado final.
      final completer = Completer<PurchaseFlowResult?>();
      late void Function() listener;
      listener = () {
        if (_state is PurchaseSucceeded) {
          final result = (_state as PurchaseSucceeded).result;
          if (!completer.isCompleted) {
            completer.complete(result);
          }
          removeListener(listener);
        } else if (_state is PurchaseFailed) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          removeListener(listener);
        }
      };
      addListener(listener);

      return completer.future.timeout(
        _watchdogDuration + const Duration(seconds: 30),
        onTimeout: () {
          removeListener(listener);
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IAP] buy failed: $e');
      }
      _fail(PurchaseFailureReason.storeError);
      return null;
    }
  }

  void resetToIdle() {
    _inFlight = false;
    _activeRequest = null;
    _cancelWatchdog();
    _setState(const PurchaseIdle());
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchases, {
    bool background = false,
  }) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (background) {
          if (kDebugMode) {
            debugPrint(
              '[IAP] background pending product=${purchase.productID}',
            );
          }
        } else {
          _handlePending(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (background) {
          if (kDebugMode) {
            debugPrint(
              '[IAP] background terminal failure product=${purchase.productID} '
              'status=${purchase.status}',
            );
          }
        } else {
          _handleTerminalFailure(purchase);
        }
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final purchaseKey = _purchaseKey(purchase);
      if (!_tryClaimPurchase(purchaseKey)) {
        continue;
      }

      if (!background) {
        _cancelWatchdog();
        _setState(const PurchaseVerifying());
      }

      // Un evento solo puede mostrar un error visible al usuario si NO es de
      // reconciliación en segundo plano Y corresponde exactamente al producto
      // que el usuario está comprando activamente ahora mismo.
      final canShowFailure = !background && _productMatchesActiveRequest(purchase.productID);

      try {
        final result = await _verifyAndFulfillWithRetry(purchase);
        if (result == null) {
          _releasePurchase(purchaseKey);
          if (canShowFailure) {
            _fail(PurchaseFailureReason.verificationFailed);
          } else if (kDebugMode) {
            debugPrint(
              '[IAP] verify returned null silently '
              'product=${purchase.productID} background=$background',
            );
          }
          continue;
        }

        await _completeVerifiedPurchase(
          purchase: purchase,
          purchaseKey: purchaseKey,
          result: result,
          background: background,
        );
      } on DioException catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed product=${purchase.productID} '
            'background=$background '
            'status=${e.response?.statusCode} code=${_readApiErrorCode(e)}',
          );
        }
        _releasePurchase(purchaseKey);
        final recovered = await _tryRecoverViaServerReconcile(purchase);
        if (recovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: recovered,
            background: background,
          );
          continue;
        }
        if (canShowFailure) {
          _fail(
            PurchaseFailureReason.verificationFailed,
            message: DioErrorMapper.map(e),
          );
        } else if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed silently product=${purchase.productID} '
            'background=$background',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed product=${purchase.productID} '
            'background=$background error=$e',
          );
        }
        _releasePurchase(purchaseKey);
        final recovered = await _tryRecoverViaServerReconcile(purchase);
        if (recovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: recovered,
            background: background,
          );
          continue;
        }
        if (canShowFailure) {
          _fail(PurchaseFailureReason.verificationFailed);
        } else if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed silently product=${purchase.productID} '
            'background=$background',
          );
        }
      }
    }
  }

  Future<void> _completeVerifiedPurchase({
    required PurchaseDetails purchase,
    required String purchaseKey,
    required PurchaseFlowResult result,
    required bool background,
  }) async {
    if (purchase.pendingCompletePurchase) {
      await completeMobileStorePurchaseIfNeeded(purchase);
    }

    if (await _shouldClearPendingStoreForProduct(purchase.productID)) {
      await _pendingStore.clear();
    }
    _markPurchaseCompleted(purchaseKey);
    await _reconcileServerPurchases();

    final matchesActive = _productMatchesActiveRequest(purchase.productID);
    final userInitiated = matchesActive && (_activeRequest?.userInitiated ?? false);
    await _refreshAfterPurchase(userInitiated: userInitiated);

    if (!background || matchesActive) {
      _inFlight = false;
      _activeRequest = null;
      _setState(PurchaseSucceeded(result));
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[IAP] background fulfilled silently product=${purchase.productID}',
      );
    }
  }

  bool _productMatchesActiveRequest(String productId) {
    final activeRequest = _activeRequest;
    if (activeRequest == null) {
      return false;
    }
    return storeProductIdsMatch(activeRequest.productId, productId);
  }

  Future<bool> _shouldClearPendingStoreForProduct(String productId) async {
    final pending = await _pendingStore.read();
    if (pending == null) {
      return false;
    }
    return storeProductIdsMatch(pending.productId, productId);
  }

  void _handlePending(PurchaseDetails purchase) {
    if (_activeRequest == null || purchase.productID != _activeRequest!.productId) {
      return;
    }
    _cancelWatchdog();
    _setState(const PurchaseDeferred());
  }

  void _handleTerminalFailure(PurchaseDetails purchase) {
    if (_activeRequest == null || purchase.productID != _activeRequest!.productId) {
      return;
    }
    _cancelWatchdog();
    if (purchase.status == PurchaseStatus.canceled) {
      _fail(PurchaseFailureReason.cancelled, message: purchase.error?.message);
    } else {
      _fail(
        PurchaseFailureReason.storeError,
        message: purchase.error?.message,
      );
    }
  }

  Future<PurchaseFlowResult?> _verifyAndFulfillWithRetry(
    PurchaseDetails purchase,
  ) async {
    DioException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
      try {
        return await _verifyAndFulfill(purchase);
      } on DioException catch (e) {
        lastError = e;
        if (attempt == 2 || !DioErrorMapper.isTransientFailure(e)) {
          rethrow;
        }
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return null;
  }

  Future<void> _reconcileServerPurchases() async {
    try {
      await _billingRepository.reconcilePendingPurchases();
    } catch (_) {}
  }

  Future<PurchaseFlowResult?> _tryRecoverViaServerReconcile(
    PurchaseDetails purchase,
  ) async {
    try {
      final result = await _billingRepository.reconcilePendingPurchases();
      if (result.fulfilledCount <= 0) {
        return null;
      }
      return await _verifyAndFulfill(purchase);
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseFlowResult?> _verifyAndFulfill(PurchaseDetails purchase) async {
    final pendingIntent = _activeRequest == null
        ? await _pendingStore.read()
        : null;

    final productId = purchase.productID;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'app_store'
        : 'google_play';
    final token = purchase.verificationData.serverVerificationData;
    final purchaseToken =
        token.isNotEmpty ? token : purchase.purchaseID ?? '';

    if (_isSubscriptionProduct(productId)) {
      final result = await _billingRepository.verifyMobilePurchase(
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId: purchase.purchaseID,
        billingCycle: _activeRequest?.billingCycle ??
            pendingIntent?.billingCycle ??
            _billingCycleForProduct(productId),
      );
      return SubscriptionPurchaseResult(planCode: result.planCode);
    }

    if (_isAiCreditProduct(productId)) {
      final result = await _billingRepository.verifyMobileAiCreditPurchase(
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId: purchase.purchaseID,
      );
      return AiCreditsPurchaseResult(creditsGranted: result.creditsGranted);
    }

    if (_isPrepProduct(productId)) {
      final prepProduct =
          _prepProducts[normalizeStoreProductId(productId).toLowerCase()];
      await _prepPlusRepository.verifyMobilePurchase(
        catalogItemId:
            _activeRequest?.catalogItemId ??
            pendingIntent?.catalogItemId ??
            prepProduct?.catalogItemId ??
            _emptyGuid,
        offerId: _activeRequest?.offerId ??
            pendingIntent?.offerId ??
            prepProduct?.offerId ??
            _emptyGuid,
        platform: platform,
        productId: productId,
        purchaseToken: purchaseToken,
        transactionId: purchase.purchaseID,
        referralCode: _activeRequest?.referralCode ?? pendingIntent?.referralCode,
      );
      return const PrepPlusPurchaseResult();
    }

    return null;
  }

  Future<void> _refreshAfterPurchase({required bool userInitiated}) async {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted && userInitiated) {
      await refreshAppSessionAfterCheckout(context);
      return;
    }
    await refreshBillingAfterStorePurchase();
  }

  Future<void> _reconcilePendingIntent() async {
    final pending = await _pendingStore.read();
    if (pending == null) {
      return;
    }

    if (!_inFlight && _activeRequest == null) {
      _activeRequest = StorePurchaseRequest(
        kind: pending.kind,
        productId: pending.productId,
        billingCycle: pending.billingCycle,
        catalogItemId: pending.catalogItemId,
        offerId: pending.offerId,
        referralCode: pending.referralCode,
        userInitiated: false,
      );
    }

    await _restorePurchases(force: true);
  }

  Future<void> _reconcileUnfinishedStoreTransactions({
    String? productId,
    bool background = false,
  }) async {
    final unfinished = await listIosUnfinishedStorePurchases();
    if (unfinished.isEmpty) {
      return;
    }

    final toProcess = productId == null
        ? unfinished
        : unfinished.where((purchase) => purchase.productID == productId).toList();

    if (toProcess.isEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[IAP] reconciling ${toProcess.length} unfinished StoreKit transaction(s)',
      );
    }

    for (final purchase in toProcess) {
      await _onPurchaseUpdate([purchase], background: background);
    }
  }

  Future<bool> _launchStorePurchase({
    required StorePurchaseRequest request,
    required PurchaseParam param,
    bool allowDuplicateRetry = true,
  }) async {
    try {
      final launched = request.kind == PurchaseProductKind.aiCredits ||
              request.kind == PurchaseProductKind.prepPlus
          ? await InAppPurchase.instance.buyConsumable(purchaseParam: param)
          : await InAppPurchase.instance
              .buyNonConsumable(purchaseParam: param);

      if (!launched) {
        _fail(PurchaseFailureReason.storeError);
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      if (allowDuplicateRetry && isIosDuplicateUnfinishedStoreError(e)) {
        if (kDebugMode) {
          debugPrint(
            '[IAP] duplicate unfinished transaction for ${request.productId}, reconciling',
          );
        }
        await _reconcileUnfinishedStoreTransactions(
          productId: request.productId,
          background: true,
        );
        if (_state is PurchaseSucceeded) {
          return true;
        }
        return _launchStorePurchase(
          request: request,
          param: param,
          allowDuplicateRetry: false,
        );
      }
      if (_shouldRestoreAfterPlatformError(e)) {
        await _restorePurchases(force: true);
      }
      _fail(PurchaseFailureReason.storeError, message: e.message);
      return false;
    }
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_watchdogDuration, () async {
      if (!_inFlight) {
        return;
      }
      if (kDebugMode) {
        debugPrint('[IAP] watchdog timeout product=${_activeRequest?.productId}');
      }
      await _restorePurchases(force: true);
      _fail(PurchaseFailureReason.timeout);
    });
  }

  void _cancelWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _fail(PurchaseFailureReason reason, {String? message}) {
    _cancelWatchdog();
    _inFlight = false;
    _activeRequest = null;
    _setState(PurchaseFailed(reason, message: message));
  }

  void _setState(PurchaseFlowState next) {
    _state = next;
    notifyListeners();
  }

  bool _tryClaimPurchase(String key) {
    _expireStaleInFlightKeys();
    if (_completedPurchaseKeys.contains(key)) {
      return false;
    }
    if (_inFlightPurchaseKeys.containsKey(key)) {
      return false;
    }
    _inFlightPurchaseKeys[key] = DateTime.now().toUtc();
    return true;
  }

  void _releasePurchase(String key) {
    _inFlightPurchaseKeys.remove(key);
  }

  void _markPurchaseCompleted(String key) {
    _inFlightPurchaseKeys.remove(key);
    _completedPurchaseKeys.add(key);
  }

  void _expireStaleInFlightKeys() {
    final now = DateTime.now().toUtc();
    _inFlightPurchaseKeys.removeWhere(
      (_, startedAt) => now.difference(startedAt) > _inFlightTtl,
    );
  }

  bool _shouldRestoreAfterPlatformError(PlatformException e) {
    final code = e.code.toLowerCase();
    return code.contains('duplicate') ||
        code.contains('pending') ||
        code.contains('already_owned') ||
        code.contains('itemalreadyowned');
  }

  Future<void> _restorePurchases({bool force = false}) async {
    if (!await isMobileStoreAvailable()) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastRestoreAt != null &&
        now.difference(_lastRestoreAt!) < _restoreThrottle) {
      return;
    }
    _lastRestoreAt = now;
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _refreshProductCatalog() async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    try {
      final packs = await _billingRepository.getAiCreditPacks();
      _aiCreditProductIds = {
        for (final pack in packs)
          if (pack.storeProductId(isIos: isIos) != null)
            pack.storeProductId(isIos: isIos)!,
      };
    } catch (_) {}

    try {
      final plans = await _billingRepository.getUpgradeablePlans();
      _plans = plans;
      _subscriptionProductIds = {
        for (final plan in plans) ...plan.nativeStoreProductIds(isIos: isIos),
      };
    } catch (_) {}

    try {
      final prepProducts = await _prepPlusRepository.getMobileStoreProducts();
      _prepProducts = {
        for (final product in prepProducts)
          normalizeStoreProductId(product.storeProductId).toLowerCase(): product,
      };
    } catch (_) {}
  }

  bool _isAiCreditProduct(String productId) {
    if (_aiCreditProductIds.contains(productId)) {
      return true;
    }
    return productId.toLowerCase().contains('ai_credits');
  }

  bool _isSubscriptionProduct(String productId) {
    if (_subscriptionProductIds.contains(productId)) {
      return true;
    }
    final lower = productId.toLowerCase();
    return lower.contains('_pro_') || lower.contains('_teacher_');
  }

  bool _isPrepProduct(String productId) {
    final normalized = normalizeStoreProductId(productId).toLowerCase();
    if (_prepProducts.containsKey(normalized)) {
      return true;
    }
    return normalized.startsWith('craftquest_prep_') ||
        normalized.contains('_prep_');
  }

  String _billingCycleForProduct(String productId) {
    for (final plan in _plans) {
      if (plan.googlePlayAnnualProductId == productId ||
          plan.appStoreAnnualProductId == productId) {
        return 'annual';
      }
    }
    return 'monthly';
  }

  String _purchaseKey(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty) {
      return '${purchase.productID}|$token';
    }
    return '${purchase.productID}|${purchase.purchaseID ?? purchase.transactionDate ?? ''}';
  }

  String? _readApiErrorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code']?.toString();
    }
    return null;
  }
}
