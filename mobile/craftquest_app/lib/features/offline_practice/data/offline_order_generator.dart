import 'dart:math';

import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_local_grader.dart';

class OfflineSessionOrder {
  const OfflineSessionOrder({
    required this.questionOrder,
    required this.answerOrderByQuestion,
  });

  final List<String> questionOrder;
  final Map<String, List<String>> answerOrderByQuestion;
}

OfflineSessionOrder generateFreshOrder(
  OfflineQuizPackageModel quiz, {
  Random? random,
}) {
  final rng = random ?? Random();
  final canonicalQuestions = List<OfflinePackageQuestionModel>.from(quiz.questions)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final questionOrder = canonicalQuestions.map((q) => q.questionId).toList();
  if (quiz.randomizeQuestions && questionOrder.length > 1) {
    _shuffleInPlace(questionOrder, rng);
  }

  final answerOrderByQuestion = <String, List<String>>{};
  for (final question in canonicalQuestions) {
    final displayOptions = question.answerOptions
        .where((o) => !OfflineLocalGrader.isQuestionImageStem(o.stableKey))
        .toList()
      ..sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));

    final optionIds = displayOptions.map((o) => o.answerOptionId).toList();
    if (question.randomizeAnswerOptions && optionIds.length > 1) {
      _shuffleInPlace(optionIds, rng);
    }
    answerOrderByQuestion[question.questionId] = optionIds;
  }

  return OfflineSessionOrder(
    questionOrder: questionOrder,
    answerOrderByQuestion: answerOrderByQuestion,
  );
}

bool isValidOrderForQuiz({
  required OfflineSessionOrder order,
  required OfflineQuizPackageModel quiz,
}) {
  final expectedQuestionIds = quiz.questions.map((q) => q.questionId).toSet();
  if (order.questionOrder.length != expectedQuestionIds.length ||
      order.questionOrder.toSet().length != expectedQuestionIds.length ||
      !order.questionOrder.every(expectedQuestionIds.contains)) {
    return false;
  }

  for (final question in quiz.questions) {
    final expectedOptionIds = question.answerOptions
        .where((o) => !OfflineLocalGrader.isQuestionImageStem(o.stableKey))
        .map((o) => o.answerOptionId)
        .toSet();
    final storedOptionIds = order.answerOrderByQuestion[question.questionId];
    if (storedOptionIds == null ||
        storedOptionIds.length != expectedOptionIds.length ||
        storedOptionIds.toSet().length != expectedOptionIds.length ||
        !storedOptionIds.every(expectedOptionIds.contains)) {
      return false;
    }
  }

  return true;
}

void _shuffleInPlace<T>(List<T> list, Random random) {
  for (var i = list.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}
