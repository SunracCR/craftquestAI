import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';

class TeacherDashboardRepository {
  TeacherDashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<TeacherDashboardModel> getDashboard() async {
    final response = await _apiClient.dio
        .get<Map<String, dynamic>>('/api/teacher/dashboard');
    return TeacherDashboardModel.fromJson(response.data!);
  }

  Future<List<ActivityFeedItemModel>> getActivityFeed({int take = 30}) async {
    final response = await _apiClient.dio
        .get<List<dynamic>>('/api/teacher/activity-feed', queryParameters: {'take': take});
    return (response.data ?? [])
        .map((e) => ActivityFeedItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentAnalyticsModel> getAssignmentAnalytics(
    String assignmentId,
  ) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/teacher/assignments/$assignmentId/analytics',
    );
    return AssignmentAnalyticsModel.fromJson(response.data!);
  }

  Future<ClassAnalyticsModel> getClassAnalytics(String classId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/teacher/classes/$classId/analytics');
    return ClassAnalyticsModel.fromJson(response.data!);
  }
}
