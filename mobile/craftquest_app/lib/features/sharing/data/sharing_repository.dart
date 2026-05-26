import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/sharing/data/models/sharing_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class SharingRepository {
  SharingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ShareCodeModel> createShareCode({
    required String quizId,
    String? accessPolicy,
    String? classId,
    int? maxRedemptions,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes/$quizId/share-code',
      data: {
        if (accessPolicy != null) 'accessPolicy': accessPolicy,
        if (classId != null) 'classId': classId,
        if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      },
    );
    return ShareCodeModel.fromJson(response.data!);
  }

  Future<ShareCodeModel?> getQuizShareCode(String quizId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/quizzes/$quizId/share-code',
      );
      return ShareCodeModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<RedeemResultModel> redeemCode(String code) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/sharing/share-codes/redeem',
      data: {'code': code},
    );
    return RedeemResultModel.fromJson(response.data!);
  }

  Future<List<AccessibleQuizModel>> getAccessibleQuizzes() async {
    final response =
        await _apiClient.dio.get<List<dynamic>>('/api/sharing/accessible-quizzes');
    return (response.data ?? [])
        .map((e) => AccessibleQuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeAccessibleQuiz(String quizId) async {
    await _apiClient.dio.delete<void>(
      '/api/sharing/accessible-quizzes/$quizId',
    );
  }

  Future<InviteUsersResultModel> inviteUsersByEmail({
    required String quizId,
    required List<String> emails,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/quizzes/$quizId/invitations',
      data: {'emails': emails},
    );
    return InviteUsersResultModel.fromJson(response.data!);
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
