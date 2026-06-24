import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:craftquest_app/core/assets/audio_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lazy singleton for practice session sound effects.
class SoundService {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, Future<AudioPlayer>> _loadingPlayers = {};
  static final Map<String, Uint8List> _bytesCache = {};
  Future<void>? _warmUpFuture;
  Future<void>? _audioContextFuture;

  /// Preloads SFX sources so the first tap plays without asset decode delay.
  Future<void> warmUp() {
    return _warmUpFuture ??= _warmUp();
  }

  Future<void> _warmUp() async {
    await _ensureAudioContext();
    await Future.wait([
      _preloadBytes(AudioAssets.sfxStart),
      _preloadBytes(AudioAssets.sfxNav),
      _preloadBytes(AudioAssets.sfxSelect),
      _preloadBytes(AudioAssets.sfxFinish),
      _ensurePlayer(AudioAssets.sfxStart),
      _ensurePlayer(AudioAssets.sfxNav),
      _ensurePlayer(AudioAssets.sfxSelect),
      _ensurePlayer(AudioAssets.sfxFinish),
    ]);
  }

  void playStartSfx() => playSfx(AudioAssets.sfxStart);

  void playNavSfx() => playSfx(AudioAssets.sfxNav);

  void playSelectSfx() => playSfx(AudioAssets.sfxSelect);

  void playFinishSfx() => playSfx(AudioAssets.sfxFinish);

  void playSfx(
    String assetPath, {
    double volume = 1,
    double playbackRate = 1,
  }) {
    unawaited(_playSfx(
      assetPath,
      volume: volume,
      playbackRate: playbackRate,
    ));
  }

  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    _loadingPlayers.clear();
    _warmUpFuture = null;
    _audioContextFuture = null;
    await Future.wait(players.map((player) => player.dispose()));
  }

  Future<void> _playSfx(
    String assetPath, {
    double volume = 1,
    double playbackRate = 1,
  }) async {
    try {
      await warmUp();
      final player = await _ensurePlayer(assetPath);
      unawaited(player.stop());
      if (volume != 1) {
        await player.setVolume(volume.clamp(0, 1));
      }
      if (playbackRate != 1) {
        await player.setPlaybackRate(playbackRate.clamp(0.5, 2));
      }
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SoundService.playSfx failed: $e\n$st');
      }
    }
  }

  Future<AudioPlayer> _ensurePlayer(String assetPath) async {
    final cached = _players[assetPath];
    if (cached != null) {
      return cached;
    }

    final inFlight = _loadingPlayers[assetPath];
    if (inFlight != null) {
      return inFlight;
    }

    final loadFuture = _createPlayer(assetPath);
    _loadingPlayers[assetPath] = loadFuture;
    try {
      final player = await loadFuture;
      _players[assetPath] = player;
      return player;
    } finally {
      _loadingPlayers.remove(assetPath);
    }
  }

  Future<AudioPlayer> _createPlayer(String assetPath) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    final bytes = await _preloadBytes(assetPath);
    await player.setSource(BytesSource(bytes, mimeType: 'audio/mpeg'));
    return player;
  }

  Future<Uint8List> _preloadBytes(String assetPath) async {
    final cached = _bytesCache[assetPath];
    if (cached != null) {
      return cached;
    }
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _bytesCache[assetPath] = bytes;
    return bytes;
  }

  Future<void> _ensureAudioContext() {
    return _audioContextFuture ??= AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ),
    );
  }
}
