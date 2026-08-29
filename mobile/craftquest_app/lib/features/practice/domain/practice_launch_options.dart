/// Options chosen before starting a practice session.
class PracticeLaunchOptions {
  const PracticeLaunchOptions({
    this.randomizeQuestions = false,
    this.showTimer = true,
    this.enableSoundEffects = true,
    this.catalogItemId,
    this.sectionIds = const [],
    this.topicIds = const [],
    this.difficulty,
    this.questionCount,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableSoundEffects;
  final String? catalogItemId;
  final List<String> sectionIds;
  final List<String> topicIds;
  final String? difficulty;
  final int? questionCount;

  bool get isCustomPrepPractice =>
      catalogItemId != null &&
      (sectionIds.isNotEmpty ||
          topicIds.isNotEmpty ||
          difficulty != null ||
          questionCount != null);

  static const PracticeLaunchOptions defaults = PracticeLaunchOptions();

  PracticeLaunchOptions copyWith({
    bool? randomizeQuestions,
    bool? showTimer,
    bool? enableSoundEffects,
    String? catalogItemId,
    List<String>? sectionIds,
    List<String>? topicIds,
    String? difficulty,
    int? questionCount,
    bool clearDifficulty = false,
    bool clearQuestionCount = false,
  }) {
    return PracticeLaunchOptions(
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      showTimer: showTimer ?? this.showTimer,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      sectionIds: sectionIds ?? this.sectionIds,
      topicIds: topicIds ?? this.topicIds,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      questionCount:
          clearQuestionCount ? null : (questionCount ?? this.questionCount),
    );
  }
}
