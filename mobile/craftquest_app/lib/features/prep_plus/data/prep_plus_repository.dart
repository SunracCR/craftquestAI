import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

class _TimedCache<T> {
  _TimedCache(this.value, this.cachedAt);

  final T value;
  final DateTime cachedAt;
}

class PrepPlusRepository {
  PrepPlusRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _categoriesTtl = Duration(minutes: 10);
  static const _browseTtl = Duration(minutes: 2);

  _TimedCache<List<PrepCategoryModel>>? _categoriesCache;
  final Map<String, _TimedCache<List<PrepBrowseItemModel>>> _browseCache = {};

  Future<List<PrepCategoryModel>> getCategories({bool forceRefresh = false}) async {
    final cached = _categoriesCache;
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _categoriesTtl) {
      return cached.value;
    }

    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/prep/categories');
    final categories = (response.data ?? [])
        .map((e) => PrepCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _categoriesCache = _TimedCache(categories, DateTime.now());
    return categories;
  }

  /// Precarga categorías en segundo plano (p. ej. al iniciar sesión).
  Future<void> prefetchCategories() async {
    try {
      await getCategories();
    } catch (_) {
      // Best effort.
    }
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = _browseCacheKey(
      categoryId: categoryId,
      search: search,
      priceFilter: priceFilter,
      institutionTag: institutionTag,
      tags: tags,
      userAccessFilter: userAccessFilter,
      skip: skip,
      take: take,
    );

    if (!forceRefresh) {
      final cached = _browseCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < _browseTtl) {
        return cached.value;
      }
    }

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
    final items = (response.data ?? [])
        .map((e) => PrepBrowseItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _browseCache[cacheKey] = _TimedCache(items, DateTime.now());
    return items;
  }

  void invalidateBrowseCache({String? categoryId}) {
    if (categoryId == null) {
      _browseCache.clear();
      return;
    }
    _browseCache.removeWhere((key, _) => key.startsWith('$categoryId|'));
  }

  String _browseCacheKey({
    required String categoryId,
    String? search,
    String? priceFilter,
    String? institutionTag,
    List<String>? tags,
    String? userAccessFilter,
    required int skip,
    required int take,
  }) {
    final tagKey = (tags ?? const []).join(',');
    return [
      categoryId,
      search ?? '',
      priceFilter ?? 'all',
      institutionTag ?? '',
      tagKey,
      userAccessFilter ?? 'all',
      skip,
      take,
    ].join('|');
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

  Future<PrepPreviewFinishResultModel> finishPreview({
    required String catalogItemId,
    required Map<String, Set<String>> selections,
    int? durationSeconds,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/preview/finish',
      data: {
        'answers': selections.entries
            .map(
              (entry) => {
                'questionId': entry.key,
                'selectedAnswerOptionIds': entry.value.toList(),
              },
            )
            .toList(),
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      },
    );
    return PrepPreviewFinishResultModel.fromJson(response.data!);
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
    invalidateBrowseCache();
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
    invalidateBrowseCache();
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
    invalidateBrowseCache();
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  String mapError(DioException error, [AppLocalizations? l10n]) =>
      DioErrorMapper.map(error, l10n ?? LocalizedMessageHolder.current);
}
