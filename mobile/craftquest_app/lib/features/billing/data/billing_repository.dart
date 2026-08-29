import 'dart:async';

import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/billing/data/billing_snapshot_store.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class BillingRepository {
  BillingRepository(this._apiClient, this._snapshotStore);

  final ApiClient _apiClient;
  final BillingSnapshotStore _snapshotStore;

  static const _cacheTtl = Duration(minutes: 2);

  UserBillingModel? _cachedBilling;
  String? _cachedUserId;
  DateTime? _cachedAt;
  Future<UserBillingModel>? _inFlightBilling;
  int _fetchGeneration = 0;

  bool get hasFreshBillingCache =>
      _cachedBilling != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _cacheTtl;

  UserBillingModel? get cachedBilling => _cachedBilling;

  Future<UserBillingModel?> preloadFromDisk(String userId) async {
    if (_cachedBilling != null && _cachedUserId == userId) {
      return _cachedBilling;
    }
    final snapshot = await _snapshotStore.read(userId);
    if (snapshot != null) {
      _cachedBilling = snapshot;
      _cachedUserId = userId;
      _cachedAt = DateTime.now();
    }
    return snapshot;
  }

  Future<UserBillingModel> getMyBilling({
    String? userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedBilling != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl &&
        (userId == null || userId == _cachedUserId)) {
      return _cachedBilling!;
    }

    if (forceRefresh) {
      _fetchGeneration++;
      _inFlightBilling = null;
    }

    _inFlightBilling ??=
        _fetchMyBilling(_fetchGeneration, userId: userId).whenComplete(() {
      _inFlightBilling = null;
    });
    return _inFlightBilling!;
  }

  void invalidateMyBillingCache() {
    _cachedBilling = null;
    _cachedUserId = null;
    _cachedAt = null;
    _fetchGeneration++;
    _inFlightBilling = null;
  }

  Future<void> clearSnapshotForUser(String userId) async {
    await _snapshotStore.clear(userId);
    if (_cachedUserId == userId) {
      invalidateMyBillingCache();
    }
  }

  Future<void> clearAllSnapshots() async {
    await _snapshotStore.clearAll();
    invalidateMyBillingCache();
  }

  Future<UserBillingModel> _fetchMyBilling(
    int generation, {
    String? userId,
  }) async {
    final response =
        await _apiClient.dio.get<Map<String, dynamic>>('/api/billing/me');
    final raw = response.data!;
    final billing = UserBillingModel.fromJson(raw);
    if (generation == _fetchGeneration) {
      _cachedBilling = billing;
      _cachedAt = DateTime.now();
      final resolvedUserId = userId ?? await _resolveCurrentUserId();
      if (resolvedUserId != null) {
        _cachedUserId = resolvedUserId;
        unawaited(_snapshotStore.save(resolvedUserId, raw));
      }
      return billing;
    }
    if (_cachedBilling != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedBilling!;
    }
    return getMyBilling(userId: userId);
  }

  Future<String?> _resolveCurrentUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId;
    }
    try {
      final response =
          await _apiClient.dio.get<Map<String, dynamic>>('/api/auth/me');
      return response.data?['userId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<PurchaseHistoryItemModel>> getMyPurchases() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/billing/purchases');
    return (response.data ?? [])
        .map(
          (e) => PurchaseHistoryItemModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<UpgradeablePlanModel>> getUpgradeablePlans() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/billing/plans');
    return (response.data ?? [])
        .map((e) => UpgradeablePlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PayPalSubscriptionModel> createPayPalSubscription(
    String planCode, {
    String billingCycle = 'monthly',
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/create-subscription',
      data: {'planCode': planCode, 'billingCycle': billingCycle},
    );
    return PayPalSubscriptionModel.fromJson(response.data!);
  }

  Future<PayPalSubscriptionActivationModel> activatePayPalSubscription(
    String subscriptionId, {
    String? billingCycle,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/activate-subscription',
      data: {
        'subscriptionId': subscriptionId,
        if (billingCycle != null) 'billingCycle': billingCycle,
      },
    );
    final result = PayPalSubscriptionActivationModel.fromJson(response.data!);
    invalidateMyBillingCache();
    return result;
  }

  Future<PayPalOrderModel> createPayPalOrder(
    String planCode, {
    String billingCycle = 'monthly',
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/create-order',
      data: {'planCode': planCode, 'billingCycle': billingCycle},
    );
    return PayPalOrderModel.fromJson(response.data!);
  }

  Future<PayPalCaptureModel> capturePayPalOrder(String orderId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/capture-order',
      data: {'orderId': orderId},
    );
    final result = PayPalCaptureModel.fromJson(response.data!);
    invalidateMyBillingCache();
    return result;
  }

  Future<VerifyPurchaseModel> verifyMobilePurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
    String billingCycle = 'monthly',
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/mobile/verify-purchase',
      data: {
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
        if (transactionId != null) 'transactionId': transactionId,
        'billingCycle': billingCycle,
      },
    );
    final result = VerifyPurchaseModel.fromJson(response.data!);
    invalidateMyBillingCache();
    return result;
  }

  Future<CancelAutoRenewModel> cancelSubscription() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/cancel',
    );
    invalidateMyBillingCache();
    return CancelAutoRenewModel.fromJson(response.data!);
  }

  Future<ReactivateAutoRenewModel> resumeAutoRenew() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/resume-auto-renew',
    );
    invalidateMyBillingCache();
    return ReactivateAutoRenewModel.fromJson(response.data!);
  }

  Future<List<AiCreditPackModel>> getAiCreditPacks() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/billing/ai-credit-packs');
    return (response.data ?? [])
        .map((e) => AiCreditPackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PayPalOrderModel> createPayPalAiCreditOrder(String packCode) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/create-ai-credit-order',
      data: {'packCode': packCode},
    );
    return PayPalOrderModel.fromJson(response.data!);
  }

  Future<PayPalAiCreditCaptureModel> capturePayPalAiCreditOrder(
    String orderId,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/capture-ai-credit-order',
      data: {'orderId': orderId},
    );
    invalidateMyBillingCache();
    return PayPalAiCreditCaptureModel.fromJson(response.data!);
  }

  Future<PayPalAiCreditCaptureModel> verifyMobileAiCreditPurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/mobile/verify-ai-credit-purchase',
      data: {
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
        if (transactionId != null) 'transactionId': transactionId,
      },
    );
    invalidateMyBillingCache();
    return PayPalAiCreditCaptureModel.fromJson(response.data!);
  }

  Future<bool> isSubscriptionExpiring({int withinDays = 7}) async {
    final response = await _apiClient.dio.get<bool>(
      '/api/billing/expiring',
      queryParameters: {'withinDays': withinDays},
    );
    return response.data ?? false;
  }

  Future<ReconcilePendingPurchasesModel> reconcilePendingPurchases() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/reconcile-pending',
    );
    invalidateMyBillingCache();
    return ReconcilePendingPurchasesModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
