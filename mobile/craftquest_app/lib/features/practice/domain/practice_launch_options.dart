/// Options chosen before starting a practice session.
class PracticeLaunchOptions {
  const PracticeLaunchOptions({
    this.randomizeQuestions = false,
    this.showTimer = true,
    this.enableSoundEffects = true,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableSoundEffects;

  static const PracticeLaunchOptions defaults = PracticeLaunchOptions();

  PracticeLaunchOptions copyWith({
    bool? randomizeQuestions,
    bool? showTimer,
    bool? enableSoundEffects,
  }) {
    return PracticeLaunchOptions(
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      showTimer: showTimer ?? this.showTimer,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
    );
  }
}
