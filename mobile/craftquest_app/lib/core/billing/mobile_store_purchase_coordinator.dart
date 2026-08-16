import 'dart:async';

import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/billing/post_checkout_session_refresh.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Procesa compras de tienda pendientes aunque el usuario no esté en la pantalla de pago.
class MobileStorePurchaseCoordinator {
  static const _restoreThrottle = Duration(seconds: 30);

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _started = false;
  int _billingPageHandlers = 0;
  DateTime? _lastRestoreAt;
  final Set<String> _handledPurchaseKeys = {};

  Set<String> _aiCreditProductIds = {};
  Set<String> _subscriptionProductIds = {};
  Map<String, PrepMobileStoreProductModel> _prepProducts = {};
  List<UpgradeablePlanModel> _plans = [];

  static const _emptyGuid = '00000000-0000-0000-0000-000000000000';

  static bool get supportsStore =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isBillingPageHandlingPurchases => _billingPageHandlers > 0;

  bool isAiCreditProduct(String productId) => _isAiCreditProduct(productId);

  bool isSubscriptionProduct(String productId) => _isSubscriptionProduct(productId);

  bool isPrepProduct(String productId) => _isPrepProduct(productId);

  String billingCycleForProduct(String productId) =>
      _billingCycleForProduct(productId);

  void pushBillingPageHandler() {
    _billingPageHandlers++;
  }

  void popBillingPageHandler() {
    if (_billingPageHandlers > 0) {
      _billingPageHandlers--;
    }
  }

  bool claimPurchase(String key) => _handledPurchaseKeys.add(key);

  void releasePurchase(String key) => _handledPurchaseKeys.remove(key);

  Future<void> start() async {
    if (!supportsStore || _started) {
      return;
    }
    _started = true;
    await _refreshProductCatalog();
    _purchaseSub =
        InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
    await _restorePurchases(force: true);
  }

  void stop() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    _started = false;
    _billingPageHandlers = 0;
    _handledPurchaseKeys.clear();
    _lastRestoreAt = null;
  }

  Future<void> onAppResume() async {
    if (!_started) {
      return;
    }
    await _refreshProductCatalog();
    await _restorePurchases();
  }

  Future<void> _refreshProductCatalog() async {
    final billingRepo = getIt<BillingRepository>();
    try {
      final packs = await billingRepo.getAiCreditPacks();
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      _aiCreditProductIds = {
        for (final pack in packs)
          if (pack.storeProductId(isIos: isIos) != null)
            pack.storeProductId(isIos: isIos)!,
      };
    } catch (_) {
      // Mantener catálogo previo o heurísticas.
    }

    try {
      final plans = await billingRepo.getUpgradeablePlans();
      _plans = plans;
      _subscriptionProductIds = {
        for (final plan in plans)
          ...{
            plan.googlePlayProductId,
            plan.googlePlayAnnualProductId,
            plan.appStoreProductId,
            plan.appStoreAnnualProductId,
          }.whereType<String>().where((id) => id.isNotEmpty),
      };
    } catch (_) {
      // Mantener catálogo previo o heurísticas.
    }

    try {
      final prepProducts = await getIt<PrepPlusRepository>().getMobileStoreProducts();
      _prepProducts = {
        for (final product in prepProducts) product.storeProductId: product,
      };
    } catch (_) {
      // Mantener catálogo previo.
    }
  }

  Future<void> _restorePurchases({bool force = false}) async {
    if (!await InAppPurchase.instance.isAvailable()) {
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

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final purchaseKey = _purchaseKey(purchase);
      if (!claimPurchase(purchaseKey)) {
        continue;
      }

      try {
        final handled = await _verifyPurchase(purchase);
        if (!handled) {
          releasePurchase(purchaseKey);
          continue;
        }

        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      } catch (_) {
        releasePurchase(purchaseKey);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    if (_isSubscriptionProduct(productId)) {
      await _verifySubscriptionPurchase(purchase);
      return true;
    }
    if (_isAiCreditProduct(productId)) {
      await _verifyAiCreditPurchase(purchase);
      return true;
    }
    if (_isPrepProduct(productId)) {
      await _verifyPrepPurchase(purchase);
      return true;
    }
    return false;
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
    if (_prepProducts.containsKey(productId)) {
      return true;
    }
    final lower = productId.toLowerCase();
    return lower.startsWith('craftquest_prep_') || lower.contains('_prep_');
  }

  Future<void> _verifyPrepPurchase(PurchaseDetails purchase) async {
    final prepRepo = getIt<PrepPlusRepository>();
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'app_store'
        : 'google_play';
    final token = purchase.verificationData.serverVerificationData;
    final product = _prepProducts[purchase.productID];

    await prepRepo.verifyMobilePurchase(
      catalogItemId: product?.catalogItemId ?? _emptyGuid,
      offerId: product?.offerId ?? _emptyGuid,
      platform: platform,
      productId: purchase.productID,
      purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
      transactionId: purchase.purchaseID,
    );
  }

  Future<void> _verifyAiCreditPurchase(PurchaseDetails purchase) async {
    final billingRepo = getIt<BillingRepository>();
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'app_store'
        : 'google_play';
    final token = purchase.verificationData.serverVerificationData;

    await billingRepo.verifyMobileAiCreditPurchase(
      platform: platform,
      productId: purchase.productID,
      purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
      transactionId: purchase.purchaseID,
    );

    final billing = await billingRepo.getMyBilling(forceRefresh: true);
    getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted(
      billing: billing,
    );
  }

  Future<void> _verifySubscriptionPurchase(PurchaseDetails purchase) async {
    final billingRepo = getIt<BillingRepository>();
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'app_store'
        : 'google_play';
    final token = purchase.verificationData.serverVerificationData;

    await billingRepo.verifyMobilePurchase(
      platform: platform,
      productId: purchase.productID,
      purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
      transactionId: purchase.purchaseID,
      billingCycle: _billingCycleForProduct(purchase.productID),
    );

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      await refreshAppSessionAfterCheckout(context);
      return;
    }

    final authRepo = getIt<AuthRepository>();
    try {
      await authRepo.refreshSession();
    } catch (_) {
      try {
        await authRepo.getProfile();
      } catch (_) {
        // Sin red: solo intentamos billing.
      }
    }

    final billing = await billingRepo.getMyBilling(forceRefresh: true);
    getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted(
      billing: billing,
    );
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
}
