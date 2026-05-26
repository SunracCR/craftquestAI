import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuestTokenStorage {
  GuestTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _visitIdKey = 'guest_visit_id';
  static const _tokenKey = 'guest_token';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String visitId,
    required String token,
  }) async {
    await _storage.write(key: _visitIdKey, value: visitId);
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<({String visitId, String token})?> load() async {
    final visitId = await _storage.read(key: _visitIdKey);
    final token = await _storage.read(key: _tokenKey);
    if (visitId == null || token == null) return null;
    return (visitId: visitId, token: token);
  }

  Future<void> clear() async {
    await _storage.delete(key: _visitIdKey);
    await _storage.delete(key: _tokenKey);
  }
}
