import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
    return _persistAndMap(response.data!);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return _persistAndMap(response.data!);
  }

  Future<UserProfileModel> getProfile() async {
    final response =
        await _apiClient.dio.get<Map<String, dynamic>>('/api/auth/me');
    return UserProfileModel.fromJson(response.data!);
  }

  Future<UserProfileModel> updateProfile({
    String? displayName,
    String? avatarId,
    String? preferredLanguage,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/api/auth/me',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (avatarId != null) 'avatarId': avatarId,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      },
    );
    return UserProfileModel.fromJson(response.data!);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() => _apiClient.tokenStorage.clear();

  Future<AuthResponseModel> _persistAndMap(Map<String, dynamic> data) async {
    final auth = AuthResponseModel.fromJson(data);
    await _apiClient.tokenStorage.saveTokens(
      accessToken: auth.tokens.accessToken,
      refreshToken: auth.tokens.refreshToken,
    );
    return auth;
  }

  String mapError(DioException error) => DioErrorMapper.map(error);
}
