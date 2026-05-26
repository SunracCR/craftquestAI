import 'dart:convert';

import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_summary_model.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class AiRepository {
  AiRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String> normalizeRawText({
    required String rawText,
    String language = 'es',
    String defaultQuestionType = 'single_choice',
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/ai/question-format/normalize',
      data: {
        'rawText': rawText,
        'language': language,
        'defaultQuestionType': defaultQuestionType,
      },
    );
    final document = response.data!['document'] as Map<String, dynamic>?;
    if (document == null) {
      throw Exception('AI response missing document');
    }
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  Future<int> clearInboxHistory() async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/api/ai/jobs/inbox-history',
    );
    return response.data?['removedCount'] as int? ?? 0;
  }

  Future<List<AiJobSummaryModel>> listJobs({String filter = 'inbox'}) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/ai/jobs',
      queryParameters: {'filter': filter},
    );
    final data = response.data ?? [];
    return data
        .map((e) => AiJobSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AiJobModel> getJob(String aiJobId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/ai/jobs/$aiJobId',
    );
    return AiJobModel.fromJson(response.data!);
  }

  Future<void> retryGenerationJob(String aiJobId) async {
    await _apiClient.dio.post<void>('/api/ai/jobs/$aiJobId/retry');
  }

  Future<void> normalizeImportBatch(String importId) async {
    await _apiClient.dio.post<void>(
      '/api/question-imports/$importId/ai-normalize',
      data: {
        'generateMissingJustifications': false,
        'validateSemantics': true,
        'useGrounding': false,
      },
    );
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
