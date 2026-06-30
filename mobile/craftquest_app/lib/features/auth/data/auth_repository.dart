import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/data/models/oauth_config_model.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<RegisterResultModel> register({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
    String? guardianEmail,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
        if (dateOfBirth != null)
          'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        if (guardianEmail != null && guardianEmail.isNotEmpty)
          'guardianEmail': guardianEmail,
      },
    );
    return RegisterResultModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> verifyEmail({required String token}) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/verify-email',
      data: {'token': token},
    );
    return _persistAndMap(response.data!);
  }

  Future<void> resendVerification({required String email}) async {
    await _apiClient.dio.post<void>(
      '/api/auth/resend-verification',
      data: {'email': email},
    );
  }

  Future<void> resendParentalConsent({required String email}) async {
    await _apiClient.dio.post<void>(
      '/api/auth/resend-parental-consent',
      data: {'email': email},
    );
  }

  Future<AuthResponseModel> confirmParentalConsent({required String token}) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/confirm-parental-consent',
      data: {'token': token},
    );
    return _persistAndMap(response.data!);
  }

  Future<void> confirmPasswordChange({required String token}) async {
    await _apiClient.dio.post<void>(
      '/api/auth/confirm-password-change',
      data: {'token': token},
    );
  }

  Future<OAuthConfigModel> getOAuthConfig() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/auth/oauth-config',
    );
    return OAuthConfigModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> loginWithGoogle({required String idToken}) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/google',
      data: {'idToken': idToken},
    );
    return _persistAndMap(response.data!);
  }

  Future<AuthResponseModel> loginWithApple({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/apple',
      data: {
        'idToken': idToken,
        if (email != null && email.isNotEmpty) 'email': email,
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

  /// Actualiza JWT (roles en el token) y devuelve el perfil desde la API.
  Future<UserProfileModel> refreshSession() async {
    final renewed = await _apiClient.refreshTokens();
    if (!renewed) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        type: DioExceptionType.badResponse,
      );
    }
    return getProfile();
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

  Future<void> requestPasswordReset({required String email}) async {
    await _apiClient.dio.post<void>(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() => _apiClient.tokenStorage.clear();

  Future<void> deleteAccount() async {
    await _apiClient.dio.delete<void>('/api/auth/me');
    await _apiClient.tokenStorage.clear();
  }

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
