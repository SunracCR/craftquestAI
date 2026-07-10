import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/ai_generation/data/models/study_material_models.dart';
import 'package:dio/dio.dart';

class StudyMaterialRepository {
  StudyMaterialRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StudyMaterialSummaryModel>> list({
    int skip = 0,
    int take = 50,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/study-materials',
      queryParameters: {'skip': skip, 'take': take},
    );
    return (response.data ?? [])
        .map((e) => StudyMaterialSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudyMaterialUploadResult> upload({
    required String fileName,
    required List<int> bytes,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (title != null && title.isNotEmpty) 'title': title,
    });

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/study-materials',
      data: formData,
    );

    return StudyMaterialUploadResult.fromJson(response.data!);
  }

  Future<void> delete(String studyMaterialId) async {
    await _apiClient.dio.delete<void>('/api/study-materials/$studyMaterialId');
  }

  Future<StudyMaterialDetailModel> getDetail(String studyMaterialId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/study-materials/$studyMaterialId',
    );
    return StudyMaterialDetailModel.fromJson(response.data!);
  }

  Future<StudyMaterialDetailModel> updateExtractedText({
    required String studyMaterialId,
    required String extractedText,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/study-materials/$studyMaterialId/extracted-text',
      data: {'extractedText': extractedText},
    );
    return StudyMaterialDetailModel.fromJson(response.data!);
  }

  Future<StudyMaterialDetailModel> updateSelection({
    required String studyMaterialId,
    String? topic,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/study-materials/$studyMaterialId/selection',
      data: {
        if (topic != null && topic.isNotEmpty) 'topic': topic,
      },
    );
    return StudyMaterialDetailModel.fromJson(response.data!);
  }

  Future<QuizGenerationEstimateModel> estimate({
    required String studyMaterialId,
    required QuizGenerationParameters parameters,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/study-materials/$studyMaterialId/generate/estimate',
      data: parameters.toJson(),
    );
    return QuizGenerationEstimateModel.fromJson(response.data!);
  }

  Future<StartQuizGenerationResult> startGeneration({
    required String studyMaterialId,
    required QuizGenerationParameters parameters,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/study-materials/$studyMaterialId/generate',
      data: parameters.toJson(),
    );
    return StartQuizGenerationResult.fromJson(response.data!);
  }
}
