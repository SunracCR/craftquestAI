import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'preferred_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _isSupported(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> applyFromProfile(String? languageCode) async {
    if (languageCode == null || !_isSupported(languageCode)) {
      return;
    }
    await setLocale(Locale(languageCode), persist: true);
  }

  Future<void> setLocale(Locale locale, {required bool persist}) async {
    if (!_isSupported(locale.languageCode)) {
      return;
    }
    _locale = locale;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }

  bool _isSupported(String code) => const {'en', 'es', 'pt'}.contains(code);
}
