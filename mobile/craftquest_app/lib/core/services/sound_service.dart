import 'package:audioplayers/audioplayers.dart';
import 'package:craftquest_app/core/assets/audio_assets.dart';
import 'package:flutter/foundation.dart';

/// Lazy singleton for practice background music and one-shot sound effects.
class SoundService {
  AudioPlayer? _musicPlayer;
  AudioPlayer? _sfxPlayer;
  bool _musicPlaying = false;
  String? _currentMusicAsset;

  Future<void> startMusic(String assetPath) async {
    if (_musicPlaying && _currentMusicAsset == assetPath) {
      return;
    }
    try {
      if (_musicPlaying) {
        await _musicPlayer?.stop();
        _musicPlaying = false;
      }
      _musicPlayer ??= AudioPlayer();
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.setVolume(0.35);
      await _musicPlayer!.play(AssetSource(_assetKey(assetPath)));
      _currentMusicAsset = assetPath;
      _musicPlaying = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SoundService.startMusic failed: $e\n$st');
      }
    }
  }

  Future<void> startMusicTrack(int trackIndex) =>
      startMusic(AudioAssets.musicTrack(trackIndex));

  Future<void> stopMusic() async {
    if (!_musicPlaying && _musicPlayer == null) {
      return;
    }
    try {
      await _musicPlayer?.stop();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SoundService.stopMusic failed: $e\n$st');
      }
    } finally {
      _musicPlaying = false;
      _currentMusicAsset = null;
    }
  }

  Future<void> playSfx(String assetPath) async {
    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.stop();
      await _sfxPlayer!.play(AssetSource(_assetKey(assetPath)));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SoundService.playSfx failed: $e\n$st');
      }
    }
  }

  Future<void> playStartSfx() => playSfx(AudioAssets.sfxStart);

  Future<void> playNavSfx() => playSfx(AudioAssets.sfxNav);

  Future<void> playFinishSfx() => playSfx(AudioAssets.sfxFinish);

  Future<void> dispose() async {
    await stopMusic();
    await _musicPlayer?.dispose();
    await _sfxPlayer?.dispose();
    _musicPlayer = null;
    _sfxPlayer = null;
  }

  static String _assetKey(String assetPath) =>
      assetPath.replaceFirst('assets/', '');
}
