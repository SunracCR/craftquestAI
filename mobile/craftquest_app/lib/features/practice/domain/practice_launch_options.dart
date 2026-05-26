/// Options chosen before starting a practice session.
class PracticeLaunchOptions {
  const PracticeLaunchOptions({
    this.randomizeQuestions = false,
    this.showTimer = true,
  });

  final bool randomizeQuestions;
  final bool showTimer;

  static const PracticeLaunchOptions defaults = PracticeLaunchOptions();
}
