import 'package:craftquest_app/core/assets/audio_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only sound preferences for practice sessions (not synced to server).
class PracticeSoundPreferences {
  const PracticeSoundPreferences({
    required this.enableMusic,
    required this.enableSoundEffects,
    required this.musicTrackIndex,
  });

  final bool enableMusic;
  final bool enableSoundEffects;
  final int musicTrackIndex;

  static const defaults = PracticeSoundPreferences(
    enableMusic: false,
    enableSoundEffects: true,
    musicTrackIndex: 0,
  );
}

class PracticeSoundPreferenceStore {
  static const _keyMusic = 'pref_practice_music';
  static const _keySfx = 'pref_practice_sfx';
  static const _keyMusicTrack = 'pref_practice_music_track';

  Future<PracticeSoundPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final trackIndex = prefs.getInt(_keyMusicTrack) ??
        PracticeSoundPreferences.defaults.musicTrackIndex;
    return PracticeSoundPreferences(
      enableMusic: prefs.getBool(_keyMusic) ??
          PracticeSoundPreferences.defaults.enableMusic,
      enableSoundEffects: prefs.getBool(_keySfx) ??
          PracticeSoundPreferences.defaults.enableSoundEffects,
      musicTrackIndex: trackIndex.clamp(0, AudioAssets.trackCount - 1),
    );
  }

  Future<void> saveMusic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusic, value);
  }

  Future<void> saveSoundEffects(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySfx, value);
  }

  Future<void> saveMusicTrackIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyMusicTrack,
      index.clamp(0, AudioAssets.trackCount - 1),
    );
  }
}
