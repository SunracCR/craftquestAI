import 'dart:io';

import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    TokenStorage? tokenStorage,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
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
    _dio.interceptors.add(AuthInterceptor(_tokenStorage));
    _configureDevHttpsCertificate(_dio);
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

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
}
