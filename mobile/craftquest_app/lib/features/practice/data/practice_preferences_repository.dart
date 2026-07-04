import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/practice/data/models/practice_preferences_models.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class _TimedCache<T> {
  _TimedCache(this.value, this.cachedAt);

  final T value;
  final DateTime cachedAt;
}

class PracticePreferencesRepository {
  PracticePreferencesRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _cacheTtl = Duration(seconds: 60);

  final Map<String, _TimedCache<QuizPracticePreferenceModel>> _cache = {};
  final Map<String, Future<QuizPracticePreferenceModel>> _inFlight = {};

  Future<QuizPracticePreferenceModel> getPreferences(String quizId) async {
    final cached = _cache[quizId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      return cached.value;
    }

    _inFlight[quizId] ??= _fetchPreferences(quizId).whenComplete(() {
      _inFlight.remove(quizId);
    });
    return _inFlight[quizId]!;
  }

  Future<QuizPracticePreferenceModel> _fetchPreferences(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/quizzes/$quizId/practice-preferences',
    );
    final prefs = QuizPracticePreferenceModel.fromJson(response.data!);
    _cache[quizId] = _TimedCache(prefs, DateTime.now());
    return prefs;
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
    final prefs = QuizPracticePreferenceModel.fromJson(response.data!);
    _cache[quizId] = _TimedCache(prefs, DateTime.now());
    return prefs;
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
