import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'preferred_locale';

  Locale? _locale;
  bool _hasManualOverride = false;

  Locale? get locale => _locale;

  /// True cuando el usuario eligió idioma explícitamente en esta sesión
  /// (login o perfil). No se persiste; nace en false al reiniciar la app.
  bool get hasManualOverride => _hasManualOverride;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _isSupported(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Aplica el idioma del perfil del servidor sin marcar override manual.
  Future<void> applyFromProfile(String? languageCode) async {
    if (languageCode == null || !_isSupported(languageCode)) {
      return;
    }
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale, {required bool persist}) async {
    if (!_isSupported(locale.languageCode)) {
      return;
    }
    _locale = locale;
    if (persist) {
      _hasManualOverride = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }

  bool _isSupported(String code) => const {'en', 'es', 'pt'}.contains(code);
}
