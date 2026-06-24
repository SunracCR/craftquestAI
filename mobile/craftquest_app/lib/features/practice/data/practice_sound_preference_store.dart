import 'package:shared_preferences/shared_preferences.dart';

/// Local-only sound preferences for practice sessions (not synced to server).
class PracticeSoundPreferences {
  const PracticeSoundPreferences({
    required this.enableSoundEffects,
  });

  final bool enableSoundEffects;

  static const defaults = PracticeSoundPreferences(
    enableSoundEffects: true,
  );
}

class PracticeSoundPreferenceStore {
  static const _keySfx = 'pref_practice_sfx';

  Future<PracticeSoundPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PracticeSoundPreferences(
      enableSoundEffects: prefs.getBool(_keySfx) ??
          PracticeSoundPreferences.defaults.enableSoundEffects,
    );
  }

  Future<void> saveSoundEffects(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySfx, value);
  }
}
