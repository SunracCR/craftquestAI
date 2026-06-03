import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<QuizAnalyticsModel> getQuizAnalytics(
    String quizId, {
    String? classId,
    String? assignmentId,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/teacher/quizzes/$quizId/analytics',
      queryParameters: {
        if (classId != null) 'classId': classId,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    return QuizAnalyticsModel.fromJson(response.data!);
  }
}
