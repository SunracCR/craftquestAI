import 'dart:async';

import 'package:craftquest_app/core/billing/ios_store_unfinished_transactions.dart';
import 'package:craftquest_app/core/billing/mobile_store_purchase_completion.dart';
import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';
import 'package:craftquest_app/core/billing/pending_store_purchase_store.dart';
import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:craftquest_app/core/billing/store_purchase_batch_policy.dart';
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
  static const _verifyMaxAttempts = 12;
  static const _inactiveSubscriptionRetryDelay = Duration(seconds: 3);
  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';

  final PendingStorePurchaseStore _pendingStore;
  final BillingRepository _billingRepository;
  final PrepPlusRepository _prepPlusRepository;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Timer? _watchdogTimer;
  bool _started = false;
  bool _inFlight = false;
  int _flowGeneration = 0;
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
    await _drainUnfinishedStoreTransactions(background: true);
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
    await _drainUnfinishedStoreTransactions(background: true);
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
    _startWatchdog();

    try {
      if (!await isMobileStoreAvailable()) {
        _fail(PurchaseFailureReason.storeUnavailable);
        return null;
      }
      if (!_inFlight) return null;

      ProductDetails? product = request.product;
      final normalizedProductId = normalizeStoreProductId(request.productId);
      product ??= await findMobileStoreProduct(normalizedProductId);
      if (!_inFlight) return null;
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
      if (!_inFlight) return null;

      await _drainUnfinishedStoreTransactions(
        preferredProductId: product.id,
        background: false,
      );
      if (_state is PurchaseSucceeded) {
        return (_state as PurchaseSucceeded).result;
      }
      if (!_inFlight) return null;

      await _reconcileUnfinishedStoreTransactions(
        productId: product.id,
        background: true,
      );
      if (_state is PurchaseSucceeded) {
        return (_state as PurchaseSucceeded).result;
      }
      if (!_inFlight) return null;

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
      if (!_inFlight || _state is PurchaseFailed) {
        return null;
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
      if (_state is PurchaseSucceeded) {
        removeListener(listener);
        return (_state as PurchaseSucceeded).result;
      }
      if (_state is PurchaseFailed || !_inFlight) {
        removeListener(listener);
        return null;
      }

      return completer.future.timeout(
        _watchdogDuration + const Duration(seconds: 30),
        onTimeout: () {
          removeListener(listener);
          if (_inFlight && _state is! PurchaseSucceeded) {
            _fail(PurchaseFailureReason.timeout);
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IAP] buy failed: $e');
      }
      if (_inFlight) {
        _fail(PurchaseFailureReason.storeError);
      }
      return null;
    }
  }

  void resetToIdle() {
    _inFlight = false;
    _activeRequest = null;
    _cancelWatchdog();
    _setState(const PurchaseIdle());
  }

  /// True mientras se prepara la compra o se espera la hoja de la tienda.
  /// La verificación no se abandona: un cobro ya emitido debe poder completarse.
  bool get canAbandonStoreWait =>
      _inFlight &&
      (_state is PurchasePreparing || _state is PurchaseAwaitingStore);

  /// Hay un token de la tienda en verificación para el producto de esta compra.
  bool get isVerifyingActiveStorePurchase {
    final request = _activeRequest;
    if (request == null) {
      return false;
    }
    return _hasInFlightVerificationForProduct(request.productId);
  }

  /// Suelta la espera de la tienda. Si el cobro llega después, se verifica
  /// en segundo plano porque la compra ya no está marcada como activa.
  void cancelActivePurchase() {
    if (!canAbandonStoreWait) {
      return;
    }
    _fail(PurchaseFailureReason.cancelled);
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchases, {
    bool background = false,
  }) async {
    final successfulProductIds = _successfulProductIdsInBatch(purchases);

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
        _dispatchTerminalFailure(
          purchase,
          listenerMarkedBackground: background,
          successfulProductIds: successfulProductIds,
        );
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      // Play a veces manda la compra con estado purchased y, a la vez,
      // BillingResponse.error (tarjeta rechazada). Eso no se verifica.
      if (purchase.error != null) {
        _dispatchTerminalFailure(
          purchase,
          listenerMarkedBackground: background,
          successfulProductIds: successfulProductIds,
        );
        continue;
      }

      if (!_hasStorePurchaseToken(purchase)) {
        _dispatchTerminalFailure(
          purchase,
          listenerMarkedBackground: background,
          successfulProductIds: successfulProductIds,
        );
        continue;
      }

      final drivesUi = StorePurchaseBatchPolicy.drivesActivePurchaseUi(
        inFlight: _inFlight,
        productMatchesActiveRequest:
            _productMatchesActiveRequest(purchase.productID),
        isRestored: purchase.status == PurchaseStatus.restored,
        hasProductId: purchase.productID.trim().isNotEmpty,
        hasPurchaseToken: true,
      );
      final effectiveBackground = !drivesUi;

      final purchaseKey = _purchaseKey(purchase);
      if (!_tryClaimPurchase(purchaseKey)) {
        continue;
      }

      if (drivesUi) {
        _setState(const PurchaseVerifying());
        _startWatchdog();
      }

      // Un evento solo puede mostrar un error visible al usuario si corresponde
      // a la compra que acaba de confirmar en la hoja, con token real.
      final canShowFailure = !effectiveBackground &&
          _productMatchesActiveRequest(purchase.productID);
      final generation = _flowGeneration;

      try {
        final result = await _verifyAndFulfillWithRetry(
          purchase,
          generation: generation,
        );
        if (generation != _flowGeneration) {
          if (result != null) {
            if (!_inFlight && _state is! PurchaseSucceeded) {
              _publishSuccess(result);
            }
            await _completeVerifiedPurchase(
              purchase: purchase,
              purchaseKey: purchaseKey,
              result: result,
              background: true,
            );
          } else {
            _releasePurchase(purchaseKey);
          }
          continue;
        }
        if (result == null) {
          _releasePurchase(purchaseKey);
          final billingRecovered = await _tryRecoverViaActiveBilling(purchase);
          if (billingRecovered != null) {
            await _completeVerifiedPurchase(
              purchase: purchase,
              purchaseKey: purchaseKey,
              result: billingRecovered,
              background: effectiveBackground,
            );
            continue;
          }
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
          background: effectiveBackground,
        );
      } on DioException catch (e) {
        if (generation != _flowGeneration) {
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed product=${purchase.productID} '
            'background=$background '
            'status=${e.response?.statusCode} code=${_readApiErrorCode(e)}',
          );
        }
        _releasePurchase(purchaseKey);
        if (canShowFailure && _isDefinitiveVerificationRejection(e)) {
          _fail(
            PurchaseFailureReason.verificationFailed,
            message: DioErrorMapper.map(e),
          );
          continue;
        }
        // Transacciones caducadas de otro producto (p. ej. Pro sandbox)
        // no deben bloquear la compra activa de Tutor.
        if (_isInactiveStoreSubscriptionError(e) && !canShowFailure) {
          await completeMobileStorePurchaseIfNeeded(purchase);
          continue;
        }
        final recovered = await _tryRecoverViaServerReconcile(purchase);
        if (recovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: recovered,
            background: effectiveBackground,
          );
          continue;
        }
        final billingRecovered = await _tryRecoverViaActiveBilling(purchase);
        if (billingRecovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: billingRecovered,
            background: effectiveBackground,
          );
          continue;
        }
        if (canShowFailure && _isInactiveStoreSubscriptionError(e)) {
          await completeMobileStorePurchaseIfNeeded(purchase);
          await _reconcileServerPurchases();
          final deferredBilling = await _tryRecoverViaActiveBilling(purchase);
          if (deferredBilling != null) {
            await _completeVerifiedPurchase(
              purchase: purchase,
              purchaseKey: purchaseKey,
              result: deferredBilling,
              background: effectiveBackground,
            );
            continue;
          }
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
        if (generation != _flowGeneration) {
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed product=${purchase.productID} '
            'background=$background error=$e',
          );
        }
        _releasePurchase(purchaseKey);
        if (canShowFailure) {
          _fail(PurchaseFailureReason.verificationFailed);
          continue;
        }
        final recovered = await _tryRecoverViaServerReconcile(purchase);
        if (recovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: recovered,
            background: effectiveBackground,
          );
          continue;
        }
        final billingRecovered = await _tryRecoverViaActiveBilling(purchase);
        if (billingRecovered != null) {
          await _completeVerifiedPurchase(
            purchase: purchase,
            purchaseKey: purchaseKey,
            result: billingRecovered,
            background: effectiveBackground,
          );
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            '[IAP] verify failed silently product=${purchase.productID} '
            'background=$background',
          );
        }
      }
    }
  }

  Set<String> _successfulProductIdsInBatch(List<PurchaseDetails> purchases) {
    return purchases
        .where(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased &&
              purchase.error == null &&
              purchase.productID.trim().isNotEmpty &&
              _hasStorePurchaseToken(purchase),
        )
        .map((purchase) => purchase.productID)
        .toSet();
  }

  bool _hasStorePurchaseToken(PurchaseDetails purchase) {
    if (purchase.verificationData.serverVerificationData.trim().isNotEmpty) {
      return true;
    }
    return (purchase.purchaseID ?? '').trim().isNotEmpty;
  }

  bool get _waitingForStoreOutcome =>
      _state is PurchaseAwaitingStore ||
      _state is PurchaseVerifying ||
      _state is PurchaseDeferred;

  void _dispatchTerminalFailure(
    PurchaseDetails purchase, {
    required bool listenerMarkedBackground,
    required Set<String> successfulProductIds,
  }) {
    final surface = StorePurchaseBatchPolicy.shouldSurfaceTerminalFailure(
      listenerMarkedBackground: listenerMarkedBackground,
      inFlight: _inFlight,
      waitingForStoreOutcome: _waitingForStoreOutcome,
      productIdEmpty: purchase.productID.trim().isEmpty,
      productMatchesActiveRequest:
          _productMatchesActiveRequest(purchase.productID),
    );
    if (!surface) {
      if (kDebugMode) {
        debugPrint(
          '[IAP] background terminal failure product=${purchase.productID} '
          'status=${purchase.status}',
        );
      }
      return;
    }
    final sheetStillOpen =
        _state is PurchaseAwaitingStore || _state is PurchaseDeferred;
    final batchHasRealSuccess =
        StorePurchaseBatchPolicy.batchContainsSuccessfulPurchase(
      successfulProductIds,
      purchase.productID,
    );
    if (_shouldIgnoreTerminalFailureForPurchase(
      purchase,
      successfulProductIds: successfulProductIds,
    )) {
      // Una restauración del historial no debe tragarse el atrás o el rechazo
      // mientras la hoja de Play sigue siendo el resultado que esperamos.
      if (!(sheetStillOpen && !batchHasRealSuccess)) {
        if (kDebugMode) {
          debugPrint(
          '[IAP] ignoring terminal failure product=${purchase.productID} '
          'status=${purchase.status} (batch has a confirmed purchase)',
          );
        }
        return;
      }
    }
    _handleTerminalFailure(purchase);
  }

  bool _shouldIgnoreTerminalFailureForPurchase(
    PurchaseDetails purchase, {
    required Set<String> successfulProductIds,
  }) {
    return StorePurchaseBatchPolicy.shouldIgnoreTerminalFailure(
      matchesActiveRequest: _productMatchesActiveRequest(purchase.productID),
      batchHasSuccessfulForProduct: StorePurchaseBatchPolicy
          .batchContainsSuccessfulPurchase(
        successfulProductIds,
        purchase.productID,
      ),
    );
  }

  bool _hasInFlightVerificationForProduct(String productId) {
    for (final key in _inFlightPurchaseKeys.keys) {
      final separatorIndex = key.indexOf('|');
      if (separatorIndex <= 0) {
        continue;
      }
      final keyProductId = key.substring(0, separatorIndex);
      if (storeProductIdsMatch(keyProductId, productId)) {
        return true;
      }
    }
    return false;
  }

  bool _isDefinitiveVerificationRejection(DioException error) {
    return !DioErrorMapper.isTransientFailure(error) &&
        !_isInactiveStoreSubscriptionError(error);
  }

  void _publishSuccess(PurchaseFlowResult result) {
    if (_state is PurchaseSucceeded) {
      return;
    }
    _cancelWatchdog();
    _inFlight = false;
    _activeRequest = null;
    _setState(PurchaseSucceeded(result));
  }

  Future<void> _completeVerifiedPurchase({
    required PurchaseDetails purchase,
    required String purchaseKey,
    required PurchaseFlowResult result,
    required bool background,
  }) async {
    final matchesActive = _productMatchesActiveRequest(purchase.productID);
    final activeKind = _activeRequest?.kind;
    final userInitiated =
        matchesActive && (_activeRequest?.userInitiated ?? false);
    final affectsHomeTab = activeKind != PurchaseProductKind.prepPlus;
    // Solo una suscripción sigue en pantalla hasta que /billing/me muestra
    // el plan. Prep+ y créditos cierran el diálogo en cuanto el servidor
    // confirma el cobro; consumir la compra y reconciliar va después.
    final pollForPaidPlan = activeKind == PurchaseProductKind.subscription;
    final publishToUi = !background || matchesActive;

    if (publishToUi && !pollForPaidPlan) {
      _publishSuccess(result);
    }

    if (purchase.pendingCompletePurchase) {
      await completeMobileStorePurchaseIfNeeded(purchase);
    }

    if (await _shouldClearPendingStoreForProduct(purchase.productID)) {
      await _pendingStore.clear();
    }
    _markPurchaseCompleted(purchaseKey);
    await _reconcileServerPurchases();

    if (publishToUi && pollForPaidPlan) {
      await _refreshAfterPurchase(
        userInitiated: userInitiated,
        affectsHomeTab: affectsHomeTab,
        pollForPaidPlan: true,
      );
      _publishSuccess(result);
      return;
    }

    unawaited(
      _refreshAfterPurchase(
        userInitiated: userInitiated,
        affectsHomeTab: affectsHomeTab,
        pollForPaidPlan: false,
      ),
    );
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
    if (!_targetsActivePurchase(purchase)) {
      return;
    }
    if (_state is PurchaseSucceeded) {
      return;
    }
    // Google Play rechaza la tarjeta o cierra la hoja con productID vacío.
    // Durante la preparación ese evento todavía no es de la hoja de pago.
    // Si ya estamos esperando el resultado, el rechazo cierra el diálogo.
    if (purchase.productID.trim().isEmpty && !_waitingForStoreOutcome) {
      return;
    }
    _cancelWatchdog();
    final message = _userVisibleStoreMessage(purchase.error?.message);
    final emptyPurchase = purchase.productID.trim().isEmpty &&
        !_hasStorePurchaseToken(purchase);
    if (purchase.status == PurchaseStatus.canceled ||
        (emptyPurchase && purchase.status != PurchaseStatus.error)) {
      _fail(PurchaseFailureReason.cancelled, message: message);
    } else {
      _fail(PurchaseFailureReason.storeError, message: message);
    }
  }

  /// Un error de la hoja de pago sin productID sigue siendo de la compra activa.
  bool _targetsActivePurchase(PurchaseDetails purchase) {
    final activeRequest = _activeRequest;
    if (activeRequest == null || !_inFlight) {
      return false;
    }
    if (purchase.productID.trim().isEmpty) {
      return true;
    }
    return storeProductIdsMatch(purchase.productID, activeRequest.productId);
  }

  String? _userVisibleStoreMessage(String? message) {
    final normalized = message?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('BillingResponse.')) {
      return null;
    }
    return normalized;
  }

  Future<PurchaseFlowResult?> _verifyAndFulfillWithRetry(
    PurchaseDetails purchase, {
    required int generation,
  }) async {
    DioException? lastError;
    for (var attempt = 0; attempt < _verifyMaxAttempts; attempt++) {
      if (generation != _flowGeneration) {
        return null;
      }
      if (attempt > 0) {
        final delay = lastError != null &&
                _isInactiveStoreSubscriptionError(lastError)
            ? _inactiveSubscriptionRetryDelay
            : Duration(seconds: 2 * attempt);
        await Future<void>.delayed(delay);
        if (generation != _flowGeneration) {
          return null;
        }
      }
      try {
        return await _verifyAndFulfill(purchase);
      } on DioException catch (e) {
        lastError = e;
        final shouldRetry = DioErrorMapper.isTransientFailure(e) ||
            _isInactiveStoreSubscriptionError(e);
        if (attempt == _verifyMaxAttempts - 1 || !shouldRetry) {
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

  Future<PurchaseFlowResult?> _tryRecoverViaActiveBilling(
    PurchaseDetails purchase,
  ) async {
    if (!_isSubscriptionProduct(purchase.productID)) {
      return null;
    }

    final expectedPlan = _planCodeForProduct(purchase.productID);
    try {
      final billing = await _billingRepository.getMyBilling(forceRefresh: true);
      if (billing.subscription.status.toLowerCase() != 'active') {
        return null;
      }

      final activePlan = billing.plan.code.toLowerCase();
      if (activePlan != 'pro' &&
          activePlan != 'teacher' &&
          activePlan != 'premium') {
        return null;
      }

      if (expectedPlan != null &&
          activePlan != expectedPlan.toLowerCase()) {
        return null;
      }

      return SubscriptionPurchaseResult(planCode: billing.plan.code);
    } catch (_) {
      return null;
    }
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

  Future<void> _refreshAfterPurchase({
    required bool userInitiated,
    bool affectsHomeTab = true,
    bool pollForPaidPlan = true,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted && userInitiated) {
      await refreshAppSessionAfterCheckout(
        context,
        affectsHomeTab: affectsHomeTab,
        pollForPaidPlan: pollForPaidPlan,
      );
      return;
    }
    await refreshBillingAfterStorePurchase(
      affectsHomeTab: affectsHomeTab,
      pollForPaidPlan: pollForPaidPlan,
    );
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

  Future<void> _drainUnfinishedStoreTransactions({
    String? preferredProductId,
    bool background = true,
  }) async {
    var unfinished = await listIosUnfinishedStorePurchases();
    if (unfinished.isEmpty) {
      return;
    }

    if (preferredProductId != null) {
      unfinished = [
        ...unfinished.where(
          (purchase) => storeProductIdsMatch(purchase.productID, preferredProductId),
        ),
        ...unfinished.where(
          (purchase) => !storeProductIdsMatch(purchase.productID, preferredProductId),
        ),
      ];
    }

    for (final purchase in unfinished) {
      await _onPurchaseUpdate([purchase], background: background);
    }

    if (preferredProductId == null) {
      return;
    }

    final remaining = await listIosUnfinishedStorePurchases();
    for (final purchase in remaining) {
      if (!storeProductIdsMatch(purchase.productID, preferredProductId)) {
        continue;
      }
      await _tryFinishIfServerAlreadyValidated(purchase);
    }
  }

  Future<bool> _tryFinishIfServerAlreadyValidated(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) {
      return false;
    }

    try {
      final result = await _verifyAndFulfill(purchase);
      if (result == null) {
        return false;
      }

      await completeMobileStorePurchaseIfNeeded(purchase);
      if (await _shouldClearPendingStoreForProduct(purchase.productID)) {
        await _pendingStore.clear();
      }
      return true;
    } on DioException catch (e) {
      if (!_isAlreadyFulfilledError(e)) {
        return false;
      }
      await completeMobileStorePurchaseIfNeeded(purchase);
      if (await _shouldClearPendingStoreForProduct(purchase.productID)) {
        await _pendingStore.clear();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isAlreadyFulfilledError(DioException error) {
    final code = _readApiErrorCode(error)?.toLowerCase() ?? '';
    if (code.contains('already') || code.contains('validated')) {
      return true;
    }

    final status = error.response?.statusCode;
    return status == 200;
  }

  bool _isInactiveStoreSubscriptionError(DioException error) {
    final code = _readApiErrorCode(error)?.toUpperCase() ?? '';
    if (code == 'STORE_SUBSCRIPTION_INACTIVE' ||
        code == 'STORE_SUBSCRIPTION_NOT_READY') {
      return true;
    }
    final message = (error.response?.data is Map
            ? (error.response!.data as Map)['detail']
            : null)
        ?.toString()
        .toLowerCase();
    return message != null && message.contains('store subscription is not active');
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
        await _drainUnfinishedStoreTransactions(
          preferredProductId: request.productId,
          background: true,
        );
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
    _watchdogTimer = Timer(_watchdogDuration, () {
      if (!_inFlight) {
        return;
      }
      if (kDebugMode) {
        debugPrint('[IAP] watchdog timeout product=${_activeRequest?.productId}');
      }
      _fail(PurchaseFailureReason.timeout);
      unawaited(_restorePurchases(force: true));
    });
  }

  void _cancelWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _fail(PurchaseFailureReason reason, {String? message}) {
    _flowGeneration++;
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
      if ((plan.googlePlayAnnualProductId != null &&
              storeProductIdsMatch(plan.googlePlayAnnualProductId!, productId)) ||
          (plan.appStoreAnnualProductId != null &&
              storeProductIdsMatch(plan.appStoreAnnualProductId!, productId))) {
        return 'annual';
      }
    }
    return 'monthly';
  }

  String? _planCodeForProduct(String productId) {
    for (final plan in _plans) {
      for (final candidate in plan.nativeStoreProductIds(
        isIos: defaultTargetPlatform == TargetPlatform.iOS,
      )) {
        if (storeProductIdsMatch(candidate, productId)) {
          return plan.code;
        }
      }
    }

    final lower = productId.toLowerCase();
    if (lower.contains('_teacher_')) {
      return 'teacher';
    }
    if (lower.contains('_pro_')) {
      return 'pro';
    }
    return null;
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
      final direct = data['errorCode'] ?? data['code'];
      if (direct != null) {
        return direct.toString();
      }
      final extensions = data['extensions'];
      if (extensions is Map && extensions['errorCode'] != null) {
        return extensions['errorCode'].toString();
      }
    }
    return null;
  }
}
