import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:craftquest_app/core/assets/audio_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lazy singleton for practice session sound effects.
class SoundService {
  AudioPlayer? _sfxPlayer;
  static final Map<String, Uint8List> _webBytesCache = {};

  Future<void> playSfx(String assetPath) async {
    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.stop();
      await _playAsset(_sfxPlayer!, assetPath);
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
    await _sfxPlayer?.dispose();
    _sfxPlayer = null;
  }

  Future<void> _playAsset(AudioPlayer player, String assetPath) async {
    if (kIsWeb) {
      final bytes = await _loadWebBytes(assetPath);
      await player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      return;
    }
    await player.play(
      AssetSource(_assetKey(assetPath), mimeType: 'audio/mpeg'),
    );
  }

  Future<Uint8List> _loadWebBytes(String assetPath) async {
    final cached = _webBytesCache[assetPath];
    if (cached != null) {
      return cached;
    }
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _webBytesCache[assetPath] = bytes;
    return bytes;
  }

  static String _assetKey(String assetPath) =>
      assetPath.replaceFirst('assets/', '');
}
