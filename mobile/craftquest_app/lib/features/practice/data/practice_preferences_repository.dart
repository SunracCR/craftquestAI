import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/practice/data/models/practice_preferences_models.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class PracticePreferencesRepository {
  PracticePreferencesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<QuizPracticePreferenceModel> getPreferences(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/quizzes/$quizId/practice-preferences',
    );
    return QuizPracticePreferenceModel.fromJson(response.data!);
  }

  Future<QuizPracticePreferenceModel> savePreferences({
    required String quizId,
    required bool randomizeQuestions,
    required bool showElapsedTimer,
  }) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/quizzes/$quizId/practice-preferences',
      data: {
        'randomizeQuestions': randomizeQuestions,
        'showElapsedTimer': showElapsedTimer,
      },
    );
    return QuizPracticePreferenceModel.fromJson(response.data!);
  }

  Future<PracticeLaunchOptions> loadLaunchOptions(String quizId) async {
    try {
      final prefs = await getPreferences(quizId);
      return prefs.toLaunchOptions();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return PracticeLaunchOptions.defaults;
      }
      rethrow;
    }
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
