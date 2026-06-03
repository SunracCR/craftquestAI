import 'package:shared_preferences/shared_preferences.dart';

/// Email guardado para rellenar el login (sin contraseña).
class SavedLoginCredentialsStorage {
  SavedLoginCredentialsStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const _rememberKey = 'login_remember_enabled';
  static const _emailKey = 'login_saved_email';
  static const _legacyPasswordKey = 'login_saved_password';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> readEmail() async {
    final prefs = await _preferences;
    if (prefs.getBool(_rememberKey) != true) {
      return null;
    }

    final email = prefs.getString(_emailKey);
    if (email == null || email.isEmpty) {
      return null;
    }

    return email.trim();
  }

  Future<void> saveEmail(String email) async {
    final prefs = await _preferences;
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_emailKey, email.trim());
    await prefs.remove(_legacyPasswordKey);
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_rememberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_legacyPasswordKey);
  }
}
