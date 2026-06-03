import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

class PrepPlusRepository {
  PrepPlusRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PrepCategoryModel>> getCategories() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/prep/categories');
    return (response.data ?? [])
        .map((e) => PrepCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PrepBrowseItemModel>> browseCategoryItems({
    required String categoryId,
    String? search,
    String? priceFilter,
    String? institutionTag,
    List<String>? tags,
    String? userAccessFilter,
    int skip = 0,
    int take = 20,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/prep/categories/$categoryId/items',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (priceFilter != null && priceFilter != 'all') 'priceFilter': priceFilter,
        if (institutionTag != null && institutionTag.isNotEmpty)
          'institutionTag': institutionTag,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (userAccessFilter != null && userAccessFilter != 'all')
          'userAccessFilter': userAccessFilter,
        'skip': skip,
        'take': take,
      },
    );
    return (response.data ?? [])
        .map((e) => PrepBrowseItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrepItemDetailModel> getItem(String catalogItemId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId',
    );
    return PrepItemDetailModel.fromJson(response.data!);
  }

  Future<PrepPreviewModel> getPreview(String catalogItemId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/preview',
    );
    return PrepPreviewModel.fromJson(response.data!);
  }

  Future<PrepMyAccessesModel> getMyAccesses() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/my-accesses',
    );
    return PrepMyAccessesModel.fromJson(response.data!);
  }

  Future<PrepCheckoutResultModel> checkout({
    required String catalogItemId,
    required String offerId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/checkout',
      data: {'offerId': offerId},
    );
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  Future<PayPalOrderModel> createPayPalOrder({
    required String catalogItemId,
    required String offerId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/paypal/create-order',
      data: {'offerId': offerId},
    );
    return PayPalOrderModel.fromJson(response.data!);
  }

  Future<PrepCheckoutResultModel> capturePayPalOrder(String orderId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/paypal/capture-order',
      data: {'orderId': orderId},
    );
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  Future<PrepCheckoutResultModel> verifyMobilePurchase({
    required String catalogItemId,
    required String offerId,
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/mobile/verify-purchase',
      data: {
        'catalogItemId': catalogItemId,
        'offerId': offerId,
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
        if (transactionId != null) 'transactionId': transactionId,
      },
    );
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  String mapError(DioException error, [AppLocalizations? l10n]) =>
      DioErrorMapper.map(error, l10n ?? LocalizedMessageHolder.current);
}
