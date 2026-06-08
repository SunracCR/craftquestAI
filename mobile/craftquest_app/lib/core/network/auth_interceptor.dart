import 'dart:async';

import 'package:craftquest_app/core/auth/jwt_utils.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:dio/dio.dart';

/// Attaches the access token and refreshes it on 401 using the refresh token.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
    required Dio refreshDio,
    SessionExpiredNotifier? sessionExpiredNotifier,
  })  : _tokenStorage = tokenStorage,
        _dio = dio,
        _refreshDio = refreshDio,
        _sessionExpiredNotifier = sessionExpiredNotifier;

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;
  final SessionExpiredNotifier? _sessionExpiredNotifier;

  Completer<bool>? _refreshCompleter;

  static bool _isAuthEndpoint(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/register') ||
        path.contains('/api/auth/refresh') ||
        path.contains('/api/auth/forgot-password') ||
        path.contains('/api/auth/reset-password') ||
        path.contains('/api/auth/change-password');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await _tokenStorage.getAccessToken();
    if (token != null &&
        token.isNotEmpty &&
        JwtUtils.shouldRefreshBeforeRequest(token)) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        token = await _tokenStorage.getAccessToken();
      }
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        _isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      _sessionExpiredNotifier?.notify();
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<bool> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSessionTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final access = data?['accessToken'] as String?;
      final refresh = data?['refreshToken'] as String?;
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        await _tokenStorage.clear();
        _refreshCompleter!.complete(false);
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      _refreshCompleter!.complete(true);
      return true;
    } on DioException {
      await _clearSessionTokens();
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      await _clearSessionTokens();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearSessionTokens() => _tokenStorage.clear();
}
