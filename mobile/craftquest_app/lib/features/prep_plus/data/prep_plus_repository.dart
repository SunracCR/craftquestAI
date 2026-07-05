import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:flutter/foundation.dart';
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
  static const _myAccessesTtl = Duration(seconds: 60);
  static const _publicPreviewTtl = Duration(minutes: 5);
  static const _itemDetailTtl = Duration(seconds: 60);

  _TimedCache<List<PrepCategoryModel>>? _categoriesCache;
  _TimedCache<PrepMyAccessesModel>? _myAccessesCache;
  final Map<String, _TimedCache<List<PrepBrowseItemModel>>> _browseCache = {};
  final Map<String, _TimedCache<PrepPublicPreviewModel>> _publicPreviewCache = {};
  final Map<String, _TimedCache<PrepItemDetailModel>> _itemDetailCache = {};
  Future<List<PrepCategoryModel>>? _inFlightCategories;
  Future<PrepMyAccessesModel>? _inFlightMyAccesses;
  final Map<String, Future<PrepPublicPreviewModel>> _inFlightPublicPreviews = {};
  final Map<String, Future<PrepItemDetailModel>> _inFlightItems = {};

  Future<List<PrepCategoryModel>> getCategories({bool forceRefresh = false}) async {
    final cached = _categoriesCache;
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _categoriesTtl) {
      return cached.value;
    }

    if (forceRefresh) {
      _inFlightCategories = null;
    }

    _inFlightCategories ??= _fetchCategories().whenComplete(() {
      _inFlightCategories = null;
    });
    return _inFlightCategories!;
  }

  Future<List<PrepCategoryModel>> _fetchCategories() async {
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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PrepPlusRepository.prefetchCategories failed: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  /// Precarga mis accesos en segundo plano (p. ej. al iniciar sesión).
  Future<void> prefetchMyAccesses() async {
    try {
      await getMyAccesses();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PrepPlusRepository.prefetchMyAccesses failed: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  void invalidateMyAccessesCache() {
    _myAccessesCache = null;
    _inFlightMyAccesses = null;
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

  PrepPublicPreviewModel? peekPublicPreview(String slug) {
    final normalizedSlug = slug.trim().toLowerCase();
    final cached = _publicPreviewCache[normalizedSlug];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _publicPreviewTtl) {
      return cached.value;
    }
    return null;
  }

  PrepItemDetailModel? peekItem(String catalogItemId) {
    final cached = _itemDetailCache[catalogItemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _itemDetailTtl) {
      return cached.value;
    }
    return null;
  }

  Future<void> prefetchPublicPreview(String slug) async {
    try {
      await getPublicPreview(slug);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PrepPlusRepository.prefetchPublicPreview failed: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> prefetchItem(String catalogItemId) async {
    try {
      await getItem(catalogItemId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PrepPlusRepository.prefetchItem failed: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<PrepItemDetailModel> getItem(
    String catalogItemId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = peekItem(catalogItemId);
      if (cached != null) {
        return cached;
      }
    } else {
      _inFlightItems.remove(catalogItemId);
    }

    _inFlightItems[catalogItemId] ??=
        _fetchItem(catalogItemId).whenComplete(() {
      _inFlightItems.remove(catalogItemId);
    });
    return _inFlightItems[catalogItemId]!;
  }

  Future<PrepItemDetailModel> _fetchItem(String catalogItemId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId',
    );
    final item = PrepItemDetailModel.fromJson(response.data!);
    _itemDetailCache[catalogItemId] = _TimedCache(item, DateTime.now());
    return item;
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

  Future<PrepMyAccessesModel> getMyAccesses({bool forceRefresh = false}) async {
    final cached = _myAccessesCache;
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _myAccessesTtl) {
      return cached.value;
    }

    if (forceRefresh) {
      _inFlightMyAccesses = null;
    }

    _inFlightMyAccesses ??= _fetchMyAccesses().whenComplete(() {
      _inFlightMyAccesses = null;
    });
    return _inFlightMyAccesses!;
  }

  Future<PrepMyAccessesModel> _fetchMyAccesses() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/my-accesses',
    );
    final model = PrepMyAccessesModel.fromJson(response.data!);
    _myAccessesCache = _TimedCache(model, DateTime.now());
    return model;
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
    invalidateMyAccessesCache();
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  Future<PrepPublicPreviewModel> getPublicPreview(
    String slug, {
    bool forceRefresh = false,
  }) async {
    final normalizedSlug = slug.trim().toLowerCase();

    if (!forceRefresh) {
      final cached = peekPublicPreview(normalizedSlug);
      if (cached != null) {
        return cached;
      }
    } else {
      _inFlightPublicPreviews.remove(normalizedSlug);
    }

    _inFlightPublicPreviews[normalizedSlug] ??=
        _fetchPublicPreview(normalizedSlug).whenComplete(() {
      _inFlightPublicPreviews.remove(normalizedSlug);
    });
    return _inFlightPublicPreviews[normalizedSlug]!;
  }

  Future<PrepPublicPreviewModel> _fetchPublicPreview(String slug) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/public/items/$slug',
    );
    final preview = PrepPublicPreviewModel.fromJson(response.data!);
    _publicPreviewCache[slug] = _TimedCache(preview, DateTime.now());
    return preview;
  }

  Future<PrepCatalogItemSlugModel> resolveCatalogItemIdBySlug(String slug) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/items/by-slug/$slug',
    );
    return PrepCatalogItemSlugModel.fromJson(response.data!);
  }

  Future<PrepReferralCodeModel> getOrCreateReferralCode(
    String catalogItemId,
  ) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/referral-code',
    );
    return PrepReferralCodeModel.fromJson(response.data!);
  }

  Future<PayPalOrderModel> createPayPalOrder({
    required String catalogItemId,
    required String offerId,
    String? referralCode,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/items/$catalogItemId/paypal/create-order',
      data: {
        'offerId': offerId,
        if (referralCode != null) 'referralCode': referralCode,
      },
    );
    return PayPalOrderModel.fromJson(response.data!);
  }

  Future<PrepCheckoutResultModel> capturePayPalOrder(String orderId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/prep/paypal/capture-order',
      data: {'orderId': orderId},
    );
    invalidateBrowseCache();
    invalidateMyAccessesCache();
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  Future<PrepCheckoutResultModel> verifyMobilePurchase({
    required String catalogItemId,
    required String offerId,
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
    String? referralCode,
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
        if (referralCode != null) 'referralCode': referralCode,
      },
    );
    invalidateBrowseCache();
    invalidateMyAccessesCache();
    return PrepCheckoutResultModel.fromJson(response.data!);
  }

  String mapError(DioException error, [AppLocalizations? l10n]) =>
      DioErrorMapper.map(error, l10n ?? LocalizedMessageHolder.current);
}
