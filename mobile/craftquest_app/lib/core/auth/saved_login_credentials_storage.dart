import 'package:shared_preferences/shared_preferences.dart';

/// Credenciales de inicio de sesión guardadas localmente (SharedPreferences).
class SavedLoginCredentialsStorage {
  SavedLoginCredentialsStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const _rememberKey = 'login_remember_enabled';
  static const _emailKey = 'login_saved_email';
  static const _passwordKey = 'login_saved_password';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SavedLoginCredentials?> read() async {
    final prefs = await _preferences;
    if (prefs.getBool(_rememberKey) != true) {
      return null;
    }

    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return SavedLoginCredentials(email: email, password: password);
  }

  Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await _preferences;
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(_passwordKey, password);
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_rememberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }
}

class SavedLoginCredentials {
  const SavedLoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
