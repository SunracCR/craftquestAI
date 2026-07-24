import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineKeyStorage {
  OfflineKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _keyForQuiz(String quizId) => 'offline_pkg_key_$quizId';

  Future<void> savePackageKey({
    required String quizId,
    required String packageKeyBase64,
  }) async {
    await _storage.write(key: _keyForQuiz(quizId), value: packageKeyBase64);
  }

  Future<String?> readPackageKey(String quizId) =>
      _storage.read(key: _keyForQuiz(quizId));

  Future<void> deletePackageKey(String quizId) =>
      _storage.delete(key: _keyForQuiz(quizId));

  Future<void> clearAllPackageKeys() => _storage.deleteAll();
}
