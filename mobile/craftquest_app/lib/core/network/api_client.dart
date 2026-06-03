import 'dart:io';

import 'package:craftquest_app/core/auth/session_expired_notifier.dart';
import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/network/auth_interceptor.dart';
import 'package:craftquest_app/core/network/multipart_request_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    TokenStorage? tokenStorage,
    SessionExpiredNotifier? sessionExpiredNotifier,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _sessionExpiredNotifier = sessionExpiredNotifier,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'https://localhost:7080',
                ),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _configureDevHttpsCertificate(_dio);
    _configureDevHttpsCertificate(_refreshDio);
    _dio.interceptors.add(MultipartRequestInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: false,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: _tokenStorage,
        dio: _dio,
        refreshDio: _refreshDio,
        sessionExpiredNotifier: _sessionExpiredNotifier,
      ),
    );
  }

  final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final SessionExpiredNotifier? _sessionExpiredNotifier;

  Dio get dio => _dio;
  TokenStorage get tokenStorage => _tokenStorage;

  /// Trusts the ASP.NET dev certificate for localhost / Android emulator in debug.
  static void _configureDevHttpsCertificate(Dio dio) {
    if (kIsWeb || !kDebugMode) {
      return;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return;
    }

    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        return host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '10.0.2.2';
      };
      return client;
    };
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/status');
    return response.data ?? {};
  }

  /// Renueva access/refresh JWT con los roles actuales del usuario (p. ej. tras comprar plan teacher).
  Future<bool> refreshTokens() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
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
        return false;
      }
      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
