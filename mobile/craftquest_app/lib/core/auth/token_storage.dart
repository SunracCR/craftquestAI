import 'package:craftquest_app/core/utils/media_request_headers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    MediaRequestHeaders.invalidate();
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    final token = await _storage.read(key: _accessTokenKey);
    _cachedAccessToken = token;
    return token;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    final token = await _storage.read(key: _refreshTokenKey);
    _cachedRefreshToken = token;
    return token;
  }

  Future<void> clear() async {
    MediaRequestHeaders.invalidate();
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
