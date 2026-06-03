import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';

class TeacherAssignmentRepository {
  TeacherAssignmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AssignmentSummaryModel>> listByClass(String classId) async {
    final response = await _apiClient.dio
        .get<List<dynamic>>('/api/teacher/classes/$classId/assignments');
    return (response.data ?? [])
        .map((e) =>
            AssignmentSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentSummaryModel> createAssignment({
    required String classId,
    required String quizId,
    required String title,
    String? instructions,
    DateTime? startsAt,
    DateTime? dueAt,
    int? maxAttempts,
    String showCorrectAnswersMode = 'after_due_date',
    bool randomizeQuestions = false,
    bool allowStudentRandomizeQuestions = false,
    bool forfeitExitCountsAsAttempt = false,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/teacher/classes/$classId/assignments',
      data: {
        'quizId': quizId,
        'title': title,
        if (instructions != null) 'instructions': instructions,
        if (startsAt != null) 'startsAt': AssignmentDates.toApiIso(startsAt),
        if (dueAt != null) 'dueAt': AssignmentDates.toApiIso(dueAt),
        if (maxAttempts != null) 'maxAttempts': maxAttempts,
        'showCorrectAnswersMode': showCorrectAnswersMode,
        'randomizeQuestions': randomizeQuestions,
        'allowStudentRandomizeQuestions': allowStudentRandomizeQuestions,
        'forfeitExitCountsAsAttempt': forfeitExitCountsAsAttempt,
      },
    );
    return AssignmentSummaryModel.fromJson(response.data!);
  }

  Future<AssignmentAnalyticsModel> getAssignmentAnalytics(
    String assignmentId,
  ) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/teacher/assignments/$assignmentId/analytics',
    );
    return AssignmentAnalyticsModel.fromJson(response.data!);
  }

  Future<AssignmentDetailModel> getDetail(String assignmentId) async {
    final response = await _apiClient.dio
        .get<Map<String, dynamic>>('/api/teacher/assignments/$assignmentId');
    return AssignmentDetailModel.fromJson(response.data!);
  }

  Future<AssignmentCompletionModel> getCompletion(String assignmentId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/teacher/assignments/$assignmentId/completion');
    return AssignmentCompletionModel.fromJson(response.data!);
  }

  Future<void> closeAssignment(String assignmentId) async {
    await _apiClient.dio
        .post<void>('/api/teacher/assignments/$assignmentId/close');
  }

  Future<void> archiveAssignment(String assignmentId) async {
    await _apiClient.dio
        .post<void>('/api/teacher/assignments/$assignmentId/archive');
  }

  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    String? instructions,
    DateTime? startsAt,
    DateTime? dueAt,
    int? maxAttempts,
    required String showCorrectAnswersMode,
    required bool randomizeQuestions,
    required bool allowStudentRandomizeQuestions,
    required bool forfeitExitCountsAsAttempt,
  }) async {
    await _apiClient.dio.patch<void>(
      '/api/teacher/assignments/$assignmentId',
      data: {
        'title': title,
        if (instructions != null) 'instructions': instructions,
        if (startsAt != null) 'startsAt': AssignmentDates.toApiIso(startsAt),
        if (dueAt != null) 'dueAt': AssignmentDates.toApiIso(dueAt),
        if (maxAttempts != null) 'maxAttempts': maxAttempts,
        'showCorrectAnswersMode': showCorrectAnswersMode,
        'randomizeQuestions': randomizeQuestions,
        'allowStudentRandomizeQuestions': allowStudentRandomizeQuestions,
        'forfeitExitCountsAsAttempt': forfeitExitCountsAsAttempt,
      },
    );
  }
}
