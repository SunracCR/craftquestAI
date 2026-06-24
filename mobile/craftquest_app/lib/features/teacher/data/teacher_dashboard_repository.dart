import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';

class TeacherDashboardRepository {
  TeacherDashboardRepository(this._apiClient);

  final ApiClient _apiClient;
  TeacherDashboardModel? _cachedDashboard;
  Future<TeacherDashboardModel>? _dashboardInFlight;

  Future<void> prefetchDashboard() async {
    try {
      await getDashboard();
    } catch (_) {}
  }

  Future<TeacherDashboardModel> getDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDashboard != null) {
      return _cachedDashboard!;
    }
    if (!forceRefresh && _dashboardInFlight != null) {
      return _dashboardInFlight!;
    }

    final request = _fetchDashboard();
    _dashboardInFlight = request;
    try {
      final dashboard = await request;
      _cachedDashboard = dashboard;
      return dashboard;
    } finally {
      if (identical(_dashboardInFlight, request)) {
        _dashboardInFlight = null;
      }
    }
  }

  void invalidateDashboardCache() {
    _cachedDashboard = null;
  }

  Future<TeacherDashboardModel> _fetchDashboard() async {
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
