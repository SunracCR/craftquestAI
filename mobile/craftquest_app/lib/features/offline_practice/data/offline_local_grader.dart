import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';

const _questionImageKey = 'QUESTION_IMAGE';
const _partialScoringPolicy = 'partial_future';

class OfflineLocalGrader {
  const OfflineLocalGrader._();

  static OfflineQuestionFeedbackModel gradeQuestion({
    required OfflinePackageQuestionModel question,
    required Set<String> selectedIds,
    required List<String> correctIds,
  }) {
    if (selectedIds.isEmpty) {
      return OfflineQuestionFeedbackModel(
        isCorrect: false,
        pointsAwarded: 0,
        pointsPossible: question.points,
      );
    }

    final correctSet = correctIds.toSet();
    final grading = _gradeAnswer(
      selectedIds: selectedIds,
      correctIds: correctSet,
      supportsMultiple: question.supportsMultipleCorrectAnswers,
      scoringPolicy: question.scoringPolicy,
      pointsPossible: question.points,
    );

    return OfflineQuestionFeedbackModel(
      isCorrect: grading.isFullyCorrect,
      pointsAwarded: grading.pointsAwarded,
      pointsPossible: question.points,
    );
  }

  static OfflineLocalFinishResultModel finishSession({
    required String clientSessionId,
    required List<OfflinePackageQuestionModel> questions,
    required Map<String, Set<String>> selections,
    required Map<String, List<String>> correctAnswersByQuestion,
  }) {
    var correctCount = 0;
    var incorrectCount = 0;
    var omittedCount = 0;
    var scoreObtained = 0.0;
    var scorePossible = 0.0;

    for (final question in questions) {
      scorePossible += question.points;
      final selected = selections[question.questionId] ?? {};
      final correctIds = correctAnswersByQuestion[question.questionId] ?? [];

      if (selected.isEmpty) {
        omittedCount++;
        continue;
      }

      final feedback = gradeQuestion(
        question: question,
        selectedIds: selected,
        correctIds: correctIds,
      );
      scoreObtained += feedback.pointsAwarded;
      if (feedback.isCorrect) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    final percentage = scorePossible > 0
        ? double.parse(
            ((scoreObtained / scorePossible) * 100).toStringAsFixed(2),
          )
        : 0.0;

    return OfflineLocalFinishResultModel(
      clientSessionId: clientSessionId,
      scoreObtained: scoreObtained,
      scorePossible: scorePossible,
      percentage: percentage,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      omittedAnswers: omittedCount,
    );
  }

  static bool isQuestionImageStem(String stableKey) =>
      stableKey.toUpperCase() == _questionImageKey;

  static _GradingOutcome _gradeAnswer({
    required Set<String> selectedIds,
    required Set<String> correctIds,
    required bool supportsMultiple,
    required String scoringPolicy,
    required double pointsPossible,
  }) {
    if (supportsMultiple && _usesPartialScoring(scoringPolicy)) {
      return _gradePartialMultiple(selectedIds, correctIds, pointsPossible);
    }

    final isCorrect = _isAnswerCorrect(
      selectedIds,
      correctIds,
      supportsMultiple,
    );
    return _GradingOutcome(
      isFullyCorrect: isCorrect,
      pointsAwarded: isCorrect ? pointsPossible : 0,
    );
  }

  static bool _usesPartialScoring(String scoringPolicy) =>
      scoringPolicy.toLowerCase() == _partialScoringPolicy;

  static bool _isAnswerCorrect(
    Set<String> selectedIds,
    Set<String> correctIds,
    bool supportsMultiple,
  ) {
    if (selectedIds.isEmpty) {
      return false;
    }
    if (!supportsMultiple) {
      return selectedIds.length == 1 &&
          correctIds.length == 1 &&
          selectedIds.containsAll(correctIds);
    }
    return selectedIds.length == correctIds.length &&
        selectedIds.containsAll(correctIds);
  }

  static _GradingOutcome _gradePartialMultiple(
    Set<String> selectedIds,
    Set<String> correctIds,
    double pointsPossible,
  ) {
    if (correctIds.isEmpty || selectedIds.isEmpty) {
      return const _GradingOutcome(isFullyCorrect: false, pointsAwarded: 0);
    }

    final correctSelected = selectedIds.where(correctIds.contains).length;
    final wrongSelected = selectedIds.where((id) => !correctIds.contains(id)).length;
    final pointsPerCorrect = pointsPossible / correctIds.length;
    final raw = (correctSelected * pointsPerCorrect) -
        (wrongSelected * pointsPerCorrect);
    final awarded = raw.clamp(0, pointsPossible);
    final rounded = double.parse(awarded.toStringAsFixed(2));
    final fullyCorrect = selectedIds.length == correctIds.length &&
        selectedIds.containsAll(correctIds);

    return _GradingOutcome(
      isFullyCorrect: fullyCorrect,
      pointsAwarded: rounded,
    );
  }
}

class _GradingOutcome {
  const _GradingOutcome({
    required this.isFullyCorrect,
    required this.pointsAwarded,
  });

  final bool isFullyCorrect;
  final double pointsAwarded;
}
