import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class BillingRepository {
  BillingRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _cacheTtl = Duration(seconds: 45);

  UserBillingModel? _cachedBilling;
  DateTime? _cachedAt;
  Future<UserBillingModel>? _inFlightBilling;

  bool get hasFreshBillingCache =>
      _cachedBilling != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _cacheTtl;

  Future<UserBillingModel> getMyBilling({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedBilling != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedBilling!;
    }

    _inFlightBilling ??= _fetchMyBilling().whenComplete(() {
      _inFlightBilling = null;
    });
    return _inFlightBilling!;
  }

  void invalidateMyBillingCache() {
    _cachedBilling = null;
    _cachedAt = null;
  }

  Future<UserBillingModel> _fetchMyBilling() async {
    final response =
        await _apiClient.dio.get<Map<String, dynamic>>('/api/billing/me');
    final billing = UserBillingModel.fromJson(response.data!);
    _cachedBilling = billing;
    _cachedAt = DateTime.now();
    return billing;
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

  String mapError(DioException error) => DioErrorMapper.map(error);
}
