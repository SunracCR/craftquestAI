import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class PracticeRepository {
  PracticeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PracticeSessionModel> startSession({
    required String quizId,
    String mode = 'practice',
    bool? randomizeQuestions,
    bool showElapsedTimer = false,
    String? classId,
    String? assignmentId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/practice-sessions',
      data: {
        'quizId': quizId,
        'mode': mode,
        if (randomizeQuestions != null)
          'randomizeQuestions': randomizeQuestions,
        'showElapsedTimer': showElapsedTimer,
        'clientUtcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        if (classId != null) 'classId': classId,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
      options: Options(
        receiveTimeout: Duration(seconds: 90),
        sendTimeout: Duration(seconds: 30),
      ),
    );
    return PracticeSessionModel.fromJson(response.data!);
  }

  Future<PracticeActiveSessionModel?> getActiveSessionForQuiz(
    String quizId, {
    String? assignmentId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/api/practice-sessions/active',
      queryParameters: {
        'quizId': quizId,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    if (response.statusCode == 204 || response.data == null) {
      return null;
    }
    return PracticeActiveSessionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<PracticeActiveSessionModel>> getInProgressSessions() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/practice-sessions/in-progress',
    );
    return (response.data ?? [])
        .map(
          (e) => PracticeActiveSessionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PracticeSessionModel> getSession(String sessionId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/practice-sessions/$sessionId',
    );
    return PracticeSessionModel.fromJson(response.data!);
  }

  Future<PracticeQuestionModel> getSessionQuestion({
    required String sessionId,
    required String practiceQuestionSnapshotId,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/practice-sessions/$sessionId/questions/$practiceQuestionSnapshotId',
    );
    return PracticeQuestionModel.fromJson(response.data!);
  }

  Future<void> updateProgress({
    required String sessionId,
    required int currentQuestionIndex,
    required int elapsedSecondsBeforePause,
  }) async {
    await _apiClient.dio.patch<void>(
      '/api/practice-sessions/$sessionId/progress',
      data: {
        'currentQuestionIndex': currentQuestionIndex,
        'elapsedSecondsBeforePause': elapsedSecondsBeforePause,
      },
    );
  }

  Future<void> abandonSession(String sessionId) async {
    await _apiClient.dio.post<void>(
      '/api/practice-sessions/$sessionId/abandon',
    );
  }

  Future<void> forfeitSession(String sessionId) async {
    await _apiClient.dio.post<void>(
      '/api/practice-sessions/$sessionId/forfeit',
    );
  }

  Future<void> submitAnswer({
    required String sessionId,
    required String practiceQuestionSnapshotId,
    required List<String> selectedAnswerOptionIds,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/practice-sessions/$sessionId/questions/$practiceQuestionSnapshotId/answer',
      data: {
        'selectedAnswerOptionIds': selectedAnswerOptionIds,
      },
    );
  }

  Future<PracticeSessionResultModel> finishSession(String sessionId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/practice-sessions/$sessionId/finish',
    );
    return PracticeSessionResultModel.fromJson(response.data!);
  }

  Future<List<MyPracticeAttemptModel>> listMyQuizAttempts(String quizId) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/practice-sessions/by-quiz/$quizId/my-attempts',
    );
    return (response.data ?? [])
        .map((e) => MyPracticeAttemptModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherPracticeReviewModel> getMySessionReview(
    String sessionId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedMyReview != null &&
        _cachedMyReviewSessionId == sessionId) {
      return _cachedMyReview!;
    }
    if (!forceRefresh &&
        _myReviewInFlight != null &&
        _myReviewInFlightSessionId == sessionId) {
      return _myReviewInFlight!;
    }

    final request = _fetchMySessionReview(sessionId);
    _myReviewInFlight = request;
    _myReviewInFlightSessionId = sessionId;
    try {
      final review = await request;
      _cachedMyReview = review;
      _cachedMyReviewSessionId = sessionId;
      return review;
    } finally {
      if (identical(_myReviewInFlight, request)) {
        _myReviewInFlight = null;
        _myReviewInFlightSessionId = null;
      }
    }
  }

  Future<void> prefetchMySessionReview(String sessionId) async {
    try {
      await getMySessionReview(sessionId);
    } catch (_) {}
  }

  Future<TeacherPracticeReviewModel> _fetchMySessionReview(String sessionId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/practice-sessions/$sessionId/my-review',
    );
    return TeacherPracticeReviewModel.fromJson(response.data!);
  }

  TeacherPracticeReviewModel? _cachedMyReview;
  String? _cachedMyReviewSessionId;
  Future<TeacherPracticeReviewModel>? _myReviewInFlight;
  String? _myReviewInFlightSessionId;

  Future<MyQuizPracticeAnalyticsModel> getMyQuizAnalytics(String quizId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/practice-sessions/by-quiz/$quizId/my-analytics',
    );
    return MyQuizPracticeAnalyticsModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
