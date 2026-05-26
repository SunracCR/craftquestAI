import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';

class StudentRepository {
  StudentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StudentClassSummaryModel>> listMyClasses() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/student/classes');
    return (response.data ?? [])
        .map(
          (e) => StudentClassSummaryModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<StudentAssignmentModel>> listMyAssignments() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/student/assignments');
    return (response.data ?? [])
        .map(
          (e) => StudentAssignmentModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<StudentAssignmentAttemptModel>> listMyAssignmentAttempts(
    String assignmentId,
  ) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/student/assignments/$assignmentId/my-attempts',
    );
    return (response.data ?? [])
        .map(
          (e) =>
              StudentAssignmentAttemptModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<StudentAssignmentSummaryModel> getMyAssignmentSummary(
    String assignmentId,
  ) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/student/assignments/$assignmentId/my-summary',
    );
    return StudentAssignmentSummaryModel.fromJson(response.data!);
  }
}
