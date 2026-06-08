import 'dart:async';

import 'package:craftquest_app/core/auth/jwt_utils.dart';
import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:dio/dio.dart';

enum RefreshResult {
  success,
  authFailure,
  transientFailure,
}

/// Attaches the access token and refreshes it on 401 using the refresh token.
///
/// Uses [Interceptor] (not [QueuedInterceptor]) so a slow billing/dashboard call
/// does not block unrelated requests such as PATCH /api/auth/me.
class AuthInterceptor extends Interceptor {
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

  Completer<RefreshResult>? _refreshCompleter;

  static bool _isAuthEndpoint(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/register') ||
        path.contains('/api/auth/refresh') ||
        path.contains('/api/auth/forgot-password') ||
        path.contains('/api/auth/reset-password') ||
        path.contains('/api/auth/change-password');
  }

  static bool _isRefreshAuthFailure(DioException error) {
    final status = error.response?.statusCode;
    return status == 401 || status == 403;
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
      final result = await _refreshTokens();
      if (result == RefreshResult.success) {
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

    final refreshResult = await _refreshTokens();
    if (refreshResult != RefreshResult.success) {
      if (refreshResult == RefreshResult.authFailure) {
        _sessionExpiredNotifier?.notify();
      }
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

  Future<RefreshResult> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<RefreshResult>();
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSessionTokens();
        _refreshCompleter!.complete(RefreshResult.authFailure);
        return RefreshResult.authFailure;
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
        _refreshCompleter!.complete(RefreshResult.authFailure);
        return RefreshResult.authFailure;
      }

      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      _refreshCompleter!.complete(RefreshResult.success);
      return RefreshResult.success;
    } on DioException catch (error) {
      if (_isRefreshAuthFailure(error)) {
        await _clearSessionTokens();
        _refreshCompleter!.complete(RefreshResult.authFailure);
        return RefreshResult.authFailure;
      }
      _refreshCompleter!.complete(RefreshResult.transientFailure);
      return RefreshResult.transientFailure;
    } catch (_) {
      _refreshCompleter!.complete(RefreshResult.transientFailure);
      return RefreshResult.transientFailure;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearSessionTokens() => _tokenStorage.clear();
}
