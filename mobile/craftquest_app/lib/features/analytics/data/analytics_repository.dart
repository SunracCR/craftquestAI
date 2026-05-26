import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<QuizAnalyticsModel> getQuizAnalytics(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/teacher/quizzes/$quizId/analytics',
    );
    return QuizAnalyticsModel.fromJson(response.data!);
  }
}
