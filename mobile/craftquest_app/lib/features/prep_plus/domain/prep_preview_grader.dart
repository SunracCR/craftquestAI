import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';

const _questionImageKey = 'QUESTION_IMAGE';
const _partialScoringPolicy = 'partial_future';

class _GradingOutcome {
  const _GradingOutcome({required this.isFullyCorrect, required this.pointsAwarded});

  final bool isFullyCorrect;
  final double pointsAwarded;
}

/// Califica la simulación Prep+ en el cliente (sin round-trip al servidor).
class PrepPreviewGrader {
  const PrepPreviewGrader._();

  static PrepPreviewFinishResultModel grade({
    required PrepPreviewModel preview,
    required Map<String, Set<String>> selections,
  }) {
    final finishPackage = preview.finishPackage;
    if (finishPackage == null) {
      throw StateError('Preview finish package is missing.');
    }

    final finishByQuestionId = {
      for (final q in finishPackage.questions) q.questionId: q,
    };

    var correctCount = 0;
    var incorrectCount = 0;
    var omittedCount = 0;
    var scoreObtained = 0.0;
    var scorePossible = 0.0;
    final reviewQuestions = <TeacherQuestionReviewModel>[];

    for (var index = 0; index < preview.sampleQuestions.length; index++) {
      final question = preview.sampleQuestions[index];
      final finishMeta = finishByQuestionId[question.questionId];
      if (finishMeta == null) {
        throw StateError('Missing finish metadata for question ${question.questionId}.');
      }

      scorePossible += finishMeta.points;

      final validOptionIds = question.answerOptions.map((o) => o.answerOptionId).toSet();
      final selectedIds = (selections[question.questionId] ?? {})
          .where(validOptionIds.contains)
          .toSet();

      final correctIds = finishMeta.correctAnswerOptionIds.toSet();

      late final String answerStatus;
      late final bool? isCorrect;
      late final double pointsAwarded;

      if (selectedIds.isEmpty) {
        answerStatus = 'omitted';
        isCorrect = null;
        pointsAwarded = 0;
        omittedCount++;
      } else {
        answerStatus = 'answered';
        final grading = _gradeAnswer(
          selectedIds: selectedIds,
          correctIds: correctIds,
          supportsMultiple: finishMeta.supportsMultipleCorrectAnswers,
          scoringPolicy: finishMeta.scoringPolicy,
          pointsPossible: finishMeta.points,
        );
        pointsAwarded = grading.pointsAwarded;
        isCorrect = grading.isFullyCorrect;
        scoreObtained += pointsAwarded;

        if (grading.isFullyCorrect) {
          correctCount++;
        } else {
          incorrectCount++;
        }
      }

      reviewQuestions.add(
        _mapReviewQuestion(
          question: question,
          finishMeta: finishMeta,
          displayOrder: index,
          selectedIds: selectedIds,
          correctIds: correctIds,
          isCorrect: isCorrect,
          pointsAwarded: pointsAwarded,
          answerStatus: answerStatus,
        ),
      );
    }

    final percentage = scorePossible > 0
        ? double.parse(((scoreObtained / scorePossible) * 100).toStringAsFixed(2))
        : 0.0;

    final review = TeacherPracticeReviewModel(
      practiceSessionId: preview.catalogItemId,
      quizId: finishPackage.quizId,
      status: 'finished',
      scoreObtained: scoreObtained,
      scorePossible: scorePossible,
      finishedAt: DateTime.now().toUtc(),
      student: const TeacherStudentModel(userId: '00000000-0000-0000-0000-000000000000'),
      questions: reviewQuestions,
      revealCorrectAnswers: true,
    );

    return PrepPreviewFinishResultModel(
      catalogItemId: preview.catalogItemId,
      scoreObtained: scoreObtained,
      scorePossible: scorePossible,
      percentage: percentage,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      omittedAnswers: omittedCount,
      review: review,
    );
  }

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
          selectedIds.containsAll(correctIds) &&
          correctIds.containsAll(selectedIds);
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
    final raw = (correctSelected * pointsPerCorrect) - (wrongSelected * pointsPerCorrect);
    final awarded = raw.clamp(0, pointsPossible);
    final rounded = double.parse(awarded.toStringAsFixed(2));
    final fullyCorrect = selectedIds.length == correctIds.length &&
        selectedIds.containsAll(correctIds);

    return _GradingOutcome(isFullyCorrect: fullyCorrect, pointsAwarded: rounded);
  }

  static TeacherQuestionReviewModel _mapReviewQuestion({
    required PrepPreviewQuestionModel question,
    required PrepPreviewQuestionFinishModel finishMeta,
    required int displayOrder,
    required Set<String> selectedIds,
    required Set<String> correctIds,
    required bool? isCorrect,
    required double pointsAwarded,
    required String answerStatus,
  }) {
    final optionMedia = {
      for (final entry in finishMeta.answerOptionMediaUrls)
        entry.answerOptionId: entry.mediaUrl,
    };

    final displayOptions = question.answerOptions
        .where((o) => !_isQuestionImageStem(o.stableKey))
        .toList();

    final labels = _buildDisplayLabels(displayOptions.length);

    return TeacherQuestionReviewModel(
      practiceQuestionSnapshotId: question.questionId,
      questionId: question.questionId,
      displayOrder: displayOrder,
      questionText: question.text,
      questionMediaUrl: finishMeta.questionMediaUrl,
      isCorrect: isCorrect,
      pointsAwarded: pointsAwarded,
      pointsPossible: finishMeta.points,
      answerStatus: answerStatus,
      justificationText: finishMeta.justificationText,
      justificationSources: finishMeta.justificationSources
          .map(
            (s) => TeacherJustificationSourceReviewModel(
              title: s.title,
              sourceUrl: s.sourceUrl,
              snippet: s.snippet,
              pageNumber: s.pageNumber,
              isPrimary: s.isPrimary,
            ),
          )
          .toList(),
      answersAsDisplayedToStudent: [
        for (var i = 0; i < displayOptions.length; i++)
          TeacherAnswerReviewModel(
            answerOptionId: displayOptions[i].answerOptionId,
            stableKey: displayOptions[i].stableKey,
            displayOrder: i,
            displayLabel: i < labels.length ? labels[i] : _indexToDisplayLabel(i),
            text: displayOptions[i].text,
            mediaUrl: optionMedia[displayOptions[i].answerOptionId],
            wasSelected: selectedIds.contains(displayOptions[i].answerOptionId),
            isCorrect: correctIds.contains(displayOptions[i].answerOptionId),
          ),
      ],
    );
  }

  static bool _isQuestionImageStem(String stableKey) =>
      stableKey.toUpperCase() == _questionImageKey;

  static List<String> _buildDisplayLabels(int count) =>
      List.generate(count, _indexToDisplayLabel);

  static String _indexToDisplayLabel(int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    var label = '';
    var value = index;
    do {
      label = String.fromCharCode(65 + (value % 26)) + label;
      value = (value ~/ 26) - 1;
    } while (value >= 0);
    return label;
  }
}
