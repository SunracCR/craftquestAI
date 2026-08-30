import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedLoginCredentialsStorage', () {
    late SavedLoginCredentialsStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SavedLoginCredentialsStorage(prefs: prefs);
    });

    test('readEmail returns null when remember is disabled', () async {
      expect(await storage.readEmail(), isNull);
    });

    test('saveEmail persists trimmed email while remember is enabled', () async {
      await storage.saveEmail('  user@example.com  ');

      expect(await storage.readEmail(), 'user@example.com');
    });

    test('clear removes saved email and remember flag', () async {
      await storage.saveEmail('user@example.com');
      await storage.clear();

      expect(await storage.readEmail(), isNull);
    });
  });
}
