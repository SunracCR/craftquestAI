import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/guest/data/guest_models.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart' show TeacherPracticeReviewModel;
import 'package:dio/dio.dart';

class GuestRepository {
  GuestRepository(this._apiClient);

  final ApiClient _apiClient;

  Options _guestOptions(String token) => Options(
        headers: {'X-Guest-Token': token},
      );

  Future<GuestVisitModel> enter(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/guest/enter',
      data: {'code': code},
    );
    return GuestVisitModel.fromJson(response.data!);
  }

  Future<GuestVisitModel?> getVisit(String token) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/guest/visit',
        options: _guestOptions(token),
      );
      if (response.statusCode == 404 || response.data == null) return null;
      return GuestVisitModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PracticeSessionModel> startPractice({
    required String visitId,
    required String token,
    bool? randomizeQuestions,
    bool showElapsedTimer = false,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/guest/$visitId/practice/start',
      data: {
        if (randomizeQuestions != null) 'randomizeQuestions': randomizeQuestions,
        'showElapsedTimer': showElapsedTimer,
      },
      options: Options(
        headers: {'X-Guest-Token': token},
        receiveTimeout: Duration(seconds: 90),
        sendTimeout: Duration(seconds: 30),
      ),
    );
    return PracticeSessionModel.fromJson(response.data!);
  }

  Future<PracticeActiveSessionModel?> getActiveSession({
    required String visitId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/guest/$visitId/practice/active',
        options: _guestOptions(token),
      );
      return PracticeActiveSessionModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> abandonSession({
    required String visitId,
    required String token,
    required String sessionId,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/guest/$visitId/practice/$sessionId/abandon',
      options: _guestOptions(token),
    );
  }

  Future<PracticeSessionModel> getSession({
    required String visitId,
    required String token,
    required String sessionId,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/guest/$visitId/practice/$sessionId',
      options: _guestOptions(token),
    );
    return PracticeSessionModel.fromJson(response.data!);
  }

  Future<PracticeQuestionModel> getSessionQuestion({
    required String visitId,
    required String token,
    required String sessionId,
    required String practiceQuestionSnapshotId,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/guest/$visitId/practice/$sessionId/questions/$practiceQuestionSnapshotId',
      options: _guestOptions(token),
    );
    return PracticeQuestionModel.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String visitId,
    required String token,
    required String sessionId,
    required String snapshotId,
    required List<String> selectedAnswerOptionIds,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/guest/$visitId/practice/$sessionId/questions/$snapshotId/answer',
      data: {'selectedAnswerOptionIds': selectedAnswerOptionIds},
      options: _guestOptions(token),
    );
    return response.data!;
  }

  Future<void> updateProgress({
    required String visitId,
    required String token,
    required String sessionId,
    required int currentQuestionIndex,
    required int elapsedSecondsBeforePause,
  }) async {
    await _apiClient.dio.patch<void>(
      '/api/guest/$visitId/practice/$sessionId/progress',
      data: {
        'currentQuestionIndex': currentQuestionIndex,
        'elapsedSecondsBeforePause': elapsedSecondsBeforePause,
      },
      options: _guestOptions(token),
    );
  }

  Future<PracticeSessionResultModel> finishSession({
    required String visitId,
    required String token,
    required String sessionId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/guest/$visitId/practice/$sessionId/finish',
      options: _guestOptions(token),
    );
    return PracticeSessionResultModel.fromJson(response.data!);
  }

  Future<List<GuestAttemptModel>> listAttempts({
    required String visitId,
    required String token,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/guest/$visitId/attempts',
      options: _guestOptions(token),
    );
    return (response.data ?? [])
        .map((e) => GuestAttemptModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherPracticeReviewModel> getAttemptReview({
    required String visitId,
    required String token,
    required String sessionId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _attemptReviewCacheKey(visitId, sessionId);
    if (!forceRefresh && _cachedAttemptReviewKey == cacheKey) {
      final cached = _cachedAttemptReview;
      if (cached != null) {
        return cached;
      }
    }
    if (!forceRefresh &&
        _attemptReviewInFlight != null &&
        _attemptReviewInFlightKey == cacheKey) {
      return _attemptReviewInFlight!;
    }

    final request = _fetchAttemptReview(
      visitId: visitId,
      token: token,
      sessionId: sessionId,
    );
    _attemptReviewInFlight = request;
    _attemptReviewInFlightKey = cacheKey;
    try {
      final review = await request;
      _cachedAttemptReview = review;
      _cachedAttemptReviewKey = cacheKey;
      return review;
    } finally {
      if (identical(_attemptReviewInFlight, request)) {
        _attemptReviewInFlight = null;
        _attemptReviewInFlightKey = null;
      }
    }
  }

  Future<void> prefetchAttemptReview({
    required String visitId,
    required String token,
    required String sessionId,
  }) async {
    try {
      await getAttemptReview(
        visitId: visitId,
        token: token,
        sessionId: sessionId,
      );
    } catch (_) {}
  }

  Future<TeacherPracticeReviewModel> _fetchAttemptReview({
    required String visitId,
    required String token,
    required String sessionId,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/guest/$visitId/attempts/$sessionId/review',
      options: _guestOptions(token),
    );
    return TeacherPracticeReviewModel.fromJson(response.data!);
  }

  static String _attemptReviewCacheKey(String visitId, String sessionId) =>
      '$visitId::$sessionId';

  TeacherPracticeReviewModel? _cachedAttemptReview;
  String? _cachedAttemptReviewKey;
  Future<TeacherPracticeReviewModel>? _attemptReviewInFlight;
  String? _attemptReviewInFlightKey;

  Future<void> leave({
    required String visitId,
    required String token,
  }) async {
    await _apiClient.dio.delete<void>(
      '/api/guest/$visitId',
      options: _guestOptions(token),
    );
  }
}
