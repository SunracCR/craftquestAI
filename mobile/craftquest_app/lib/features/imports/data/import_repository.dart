import 'dart:typed_data';

import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:dio/dio.dart';

class ImportRepository {
  ImportRepository(this._apiClient);

  final ApiClient _apiClient;

  static const int maxExcelFileBytes = 5 * 1024 * 1024;

  String? _cachedPreviewImportId;
  ImportPreviewModel? _cachedPreview;
  Future<ImportPreviewModel>? _previewInFlight;

  Future<Uint8List> downloadExcelTemplate({required String languageCode}) async {
    final response = await _apiClient.dio.get<List<int>>(
      '/api/question-imports/excel-template',
      queryParameters: {'language': languageCode},
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty template response',
      );
    }
    return Uint8List.fromList(data);
  }

  Future<ImportStatusModel> processExcelFile({
    required String quizId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName.toLowerCase().endsWith('.xlsx')
        ? fileName
        : '$fileName.xlsx';

    final formData = FormData.fromMap({
      'sourceType': 'xlsx',
      'useAiNormalization': false,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: safeName,
      ),
    });

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes/$quizId/question-imports/process-file',
      data: formData,
    );
    return ImportStatusModel.fromJson(response.data!);
  }

  Future<ImportStatusModel> processImport({
    required String quizId,
    required String sourceType,
    required String rawText,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes/$quizId/question-imports/process',
      data: {
        'sourceType': sourceType,
        'rawText': rawText,
        'useAiNormalization': false,
      },
    );
    return ImportStatusModel.fromJson(response.data!);
  }

  Future<void> prefetchPreview(String importId) async {
    try {
      await getPreview(importId);
    } catch (_) {
      // Best-effort warm cache before navigation.
    }
  }

  Future<ImportPreviewModel> getPreview(
    String importId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedPreviewImportId == importId &&
        _cachedPreview != null) {
      return _cachedPreview!;
    }

    if (!forceRefresh &&
        _previewInFlight != null &&
        _cachedPreviewImportId == importId) {
      return _previewInFlight!;
    }

    final request = _fetchPreview(importId);
    _cachedPreviewImportId = importId;
    _previewInFlight = request;

    try {
      final preview = await request;
      _cachedPreview = preview;
      return preview;
    } finally {
      if (identical(_previewInFlight, request)) {
        _previewInFlight = null;
      }
    }
  }

  Future<ImportPreviewModel> _fetchPreview(String importId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/question-imports/$importId/preview',
    );
    return ImportPreviewModel.fromJson(response.data!);
  }

  Future<ImportConfirmResultModel> confirm(String importId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/question-imports/$importId/confirm',
      options: Options(
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    return ImportConfirmResultModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
