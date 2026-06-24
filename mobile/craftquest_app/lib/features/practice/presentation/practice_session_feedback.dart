import 'dart:async';

import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:flutter/services.dart';

/// Centralizes practice session sound effects and haptics.
class PracticeSessionFeedback {
  PracticeSessionFeedback(
    this._soundService, {
    bool enabled = true,
  }) : _enabled = enabled;

  final SoundService _soundService;
  bool _enabled;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  void onSelectAnswer() {
    if (_enabled) {
      _soundService.playSelectSfx();
    }
    HapticFeedback.selectionClick();
  }

  void onNextQuestion() {
    if (_enabled) {
      _soundService.playNavNextSfx();
    }
    HapticFeedback.lightImpact();
  }

  void onPreviousQuestion() {
    if (_enabled) {
      _soundService.playNavSfx();
    }
    HapticFeedback.lightImpact();
  }

  void onFinish() {
    if (_enabled) {
      _soundService.playFinishSfx();
    }
    HapticFeedback.mediumImpact();
  }

  /// Plays a short preview when the user enables sound effects in settings.
  static void previewEnabled(SoundService soundService) {
    unawaited(soundService.warmUp());
    soundService.playSelectSfx();
    HapticFeedback.selectionClick();
  }
}
