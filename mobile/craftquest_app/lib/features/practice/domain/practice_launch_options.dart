import 'package:craftquest_app/core/assets/audio_assets.dart';

/// Options chosen before starting a practice session.
class PracticeLaunchOptions {
  const PracticeLaunchOptions({
    this.randomizeQuestions = false,
    this.showTimer = true,
    this.enableMusic = false,
    this.enableSoundEffects = true,
    this.musicTrackIndex = 0,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableMusic;
  final bool enableSoundEffects;
  final int musicTrackIndex;

  static const PracticeLaunchOptions defaults = PracticeLaunchOptions();

  int get clampedMusicTrackIndex =>
      musicTrackIndex.clamp(0, AudioAssets.trackCount - 1);

  PracticeLaunchOptions copyWith({
    bool? randomizeQuestions,
    bool? showTimer,
    bool? enableMusic,
    bool? enableSoundEffects,
    int? musicTrackIndex,
  }) {
    return PracticeLaunchOptions(
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      showTimer: showTimer ?? this.showTimer,
      enableMusic: enableMusic ?? this.enableMusic,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      musicTrackIndex: musicTrackIndex ?? this.musicTrackIndex,
    );
  }
}
