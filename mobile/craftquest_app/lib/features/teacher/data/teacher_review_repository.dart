import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class TeacherReviewRepository {
  TeacherReviewRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TeacherAttemptModel>> listQuizAttempts(String quizId) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/teacher/quizzes/$quizId/practice-attempts',
    );
    return (response.data ?? [])
        .map((e) => TeacherAttemptModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherPracticeReviewModel> getSessionReview(String sessionId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/teacher/practice-sessions/$sessionId',
    );
    return TeacherPracticeReviewModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
