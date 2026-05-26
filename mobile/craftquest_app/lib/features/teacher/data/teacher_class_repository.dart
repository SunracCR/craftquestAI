import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';

class TeacherClassRepository {
  TeacherClassRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TeacherClassSummaryModel>> listClasses() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/teacher/classes');
    return (response.data ?? [])
        .map((e) =>
            TeacherClassSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherClassSummaryModel> createClass({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/teacher/classes',
      data: {'name': name, if (description != null) 'description': description},
    );
    return TeacherClassSummaryModel.fromJson(response.data!);
  }

  Future<ClassDetailModel> getClassDetail(String classId) async {
    final response = await _apiClient.dio
        .get<Map<String, dynamic>>('/api/teacher/classes/$classId');
    return ClassDetailModel.fromJson(response.data!);
  }

  Future<void> updateClass({
    required String classId,
    required String name,
    String? description,
  }) async {
    await _apiClient.dio.patch<void>(
      '/api/teacher/classes/$classId',
      data: {'name': name, if (description != null) 'description': description},
    );
  }

  Future<void> archiveClass(String classId) async {
    await _apiClient.dio
        .post<void>('/api/teacher/classes/$classId/archive');
  }

  Future<void> addMemberByEmail({
    required String classId,
    required String email,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/teacher/classes/$classId/members',
      data: {'email': email},
    );
  }

  Future<void> approveMember({
    required String classId,
    required String userId,
  }) async {
    await _apiClient.dio.patch<void>(
      '/api/teacher/classes/$classId/members/$userId',
      data: {'status': 'active'},
    );
  }

  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    await _apiClient.dio
        .delete<void>('/api/teacher/classes/$classId/members/$userId');
  }
}
