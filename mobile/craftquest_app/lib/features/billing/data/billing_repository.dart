import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class BillingRepository {
  BillingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserBillingModel> getMyBilling() async {
    final response =
        await _apiClient.dio.get<Map<String, dynamic>>('/api/billing/me');
    return UserBillingModel.fromJson(response.data!);
  }

  Future<List<UpgradeablePlanModel>> getUpgradeablePlans() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/billing/plans');
    return (response.data ?? [])
        .map((e) => UpgradeablePlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PayPalOrderModel> createPayPalOrder(String planCode) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/create-order',
      data: {'planCode': planCode, 'billingCycle': 'monthly'},
    );
    return PayPalOrderModel.fromJson(response.data!);
  }

  Future<PayPalCaptureModel> capturePayPalOrder(String orderId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/paypal/capture-order',
      data: {'orderId': orderId},
    );
    return PayPalCaptureModel.fromJson(response.data!);
  }

  Future<VerifyPurchaseModel> verifyMobilePurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/billing/mobile/verify-purchase',
      data: {
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
        if (transactionId != null) 'transactionId': transactionId,
      },
    );
    return VerifyPurchaseModel.fromJson(response.data!);
  }

  Future<void> cancelSubscription() async {
    await _apiClient.dio.post<void>('/api/billing/cancel');
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
