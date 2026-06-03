import 'package:craftquest_app/core/l10n/localized_message_holder.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_admin_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

class PrepPlusAdminRepository {
  PrepPlusAdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PrepAdminLinkableQuizModel>> getLinkableQuizzes({
    String? search,
    int take = 100,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/admin/prep/linkable-quizzes',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'take': take,
      },
    );
    return (response.data ?? [])
        .map((e) => PrepAdminLinkableQuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PrepAdminCategoryModel>> getCategories({
    bool includeInactive = true,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/admin/prep/categories',
      queryParameters: {'includeInactive': includeInactive},
    );
    return (response.data ?? [])
        .map((e) => PrepAdminCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrepAdminCategoryModel> createCategory(
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/admin/prep/categories',
      data: body,
    );
    return PrepAdminCategoryModel.fromJson(response.data!);
  }

  Future<PrepAdminCategoryModel> updateCategory(
    String categoryId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/admin/prep/categories/$categoryId',
      data: body,
    );
    return PrepAdminCategoryModel.fromJson(response.data!);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _apiClient.dio.delete<void>(
      '/api/admin/prep/categories/$categoryId',
    );
  }

  Future<List<PrepAdminItemSummaryModel>> listItems({
    String? categoryId,
    bool? isPublished,
    bool includeDeleted = false,
    String? search,
    int take = 50,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/admin/prep/items',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (isPublished != null) 'isPublished': isPublished,
        'includeDeleted': includeDeleted,
        if (search != null && search.isNotEmpty) 'search': search,
        'take': take,
      },
    );
    return (response.data ?? [])
        .map((e) => PrepAdminItemSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrepAdminItemDetailModel> getItem(String catalogItemId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId',
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> createItem(Map<String, dynamic> body) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/admin/prep/items',
      data: body,
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> updateItem(
    String catalogItemId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId',
      data: body,
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> upsertOffers(
    String catalogItemId,
    List<Map<String, dynamic>> offers,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId/offers',
      data: {'offers': offers},
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> upsertSamples(
    String catalogItemId,
    List<String> questionIds,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId/samples',
      data: {'questionIds': questionIds},
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> publishItem(String catalogItemId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId/publish',
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<PrepAdminItemDetailModel> unpublishItem(String catalogItemId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/admin/prep/items/$catalogItemId/unpublish',
    );
    return PrepAdminItemDetailModel.fromJson(response.data!);
  }

  Future<void> deleteItem(String catalogItemId) async {
    await _apiClient.dio.delete<void>(
      '/api/admin/prep/items/$catalogItemId',
    );
  }

  String mapError(DioException error, [AppLocalizations? l10n]) =>
      DioErrorMapper.map(error, l10n ?? LocalizedMessageHolder.current);
}

/// Aplana el árbol y devuelve solo subcategorías (con padre).
List<PrepAdminSubcategoryOption> flattenPrepSubcategories(
  List<PrepAdminCategoryModel> roots,
) {
  final result = <PrepAdminSubcategoryOption>[];
  for (final root in roots) {
    for (final child in root.children) {
      result.add(
        PrepAdminSubcategoryOption(
          categoryId: child.categoryId,
          label: '${root.name} → ${child.name}',
          isGeographic: root.categoryType == 'geographic',
        ),
      );
    }
  }
  return result;
}
