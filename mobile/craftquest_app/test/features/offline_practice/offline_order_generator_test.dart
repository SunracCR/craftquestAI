import 'dart:math';

import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_order_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateFreshOrder', () {
    test('preserves canonical order when randomization is disabled', () {
      final quiz = _buildQuiz(
        randomizeQuestions: false,
        randomizeAnswerOptions: false,
      );

      final order = generateFreshOrder(quiz);

      expect(order.questionOrder, ['q1', 'q2']);
      expect(order.answerOrderByQuestion['q1'], ['a1', 'a2']);
      expect(order.answerOrderByQuestion['q2'], ['a3', 'a4']);
    });

    test('shuffles questions and answer options when enabled', () {
      final quiz = _buildQuiz(
        randomizeQuestions: true,
        randomizeAnswerOptions: true,
      );

      var sawDifferentQuestionOrder = false;
      var sawDifferentAnswerOrder = false;

      for (var seed = 0; seed < 100; seed++) {
        final order = generateFreshOrder(quiz, random: Random(seed));
        expect(order.questionOrder.toSet(), {'q1', 'q2'});
        expect(order.answerOrderByQuestion['q1']!.toSet(), {'a1', 'a2'});
        expect(order.answerOrderByQuestion['q2']!.toSet(), {'a3', 'a4'});
        sawDifferentQuestionOrder |= order.questionOrder != ['q1', 'q2'];
        sawDifferentAnswerOrder |=
            order.answerOrderByQuestion['q1'] != ['a1', 'a2'];
      }

      expect(sawDifferentQuestionOrder, isTrue);
      expect(sawDifferentAnswerOrder, isTrue);
    });

    test('uses randomizeQuestionsOverride over quiz setting', () {
      final quiz = _buildQuiz(
        randomizeQuestions: false,
        randomizeAnswerOptions: false,
      );

      var sawDifferentQuestionOrder = false;
      for (var seed = 0; seed < 100; seed++) {
        final order = generateFreshOrder(
          quiz,
          randomizeQuestionsOverride: true,
          random: Random(seed),
        );
        sawDifferentQuestionOrder |= order.questionOrder != ['q1', 'q2'];
      }

      expect(sawDifferentQuestionOrder, isTrue);
    });
  });

  group('isValidOrderForQuiz', () {
    test('returns false when question ids do not match quiz', () {
      final quiz = _buildQuiz(
        randomizeQuestions: false,
        randomizeAnswerOptions: false,
      );

      final isValid = isValidOrderForQuiz(
        order: const OfflineSessionOrder(
          questionOrder: ['q1'],
          answerOrderByQuestion: {
            'q1': ['a1', 'a2'],
          },
        ),
        quiz: quiz,
      );

      expect(isValid, isFalse);
    });

    test('returns true for a complete valid order', () {
      final quiz = _buildQuiz(
        randomizeQuestions: false,
        randomizeAnswerOptions: false,
      );
      final order = generateFreshOrder(quiz);

      expect(isValidOrderForQuiz(order: order, quiz: quiz), isTrue);
    });
  });
}

OfflineQuizPackageModel _buildQuiz({
  required bool randomizeQuestions,
  required bool randomizeAnswerOptions,
}) {
  return OfflineQuizPackageModel(
    quizId: 'quiz-1',
    title: 'Quiz',
    contentVersion: 'v1',
    generatedAt: DateTime.utc(2026),
    expiresAt: DateTime.utc(2027),
    packageKeyBase64: 'key',
    randomizeQuestions: randomizeQuestions,
    defaultRandomizeAnswerOptions: randomizeAnswerOptions,
    watermarkToken: 'token',
    questions: [
      OfflinePackageQuestionModel(
        questionId: 'q1',
        sortOrder: 1,
        questionText: 'Question 1',
        questionType: 'single_choice',
        points: 1,
        randomizeAnswerOptions: randomizeAnswerOptions,
        scoringPolicy: 'strict',
        supportsMultipleCorrectAnswers: false,
        correctAnswerBlob: 'blob',
        answerOptions: [
          OfflinePackageAnswerOptionModel(
            answerOptionId: 'a1',
            stableKey: 'A',
            defaultSortOrder: 1,
            answerText: 'Option A',
          ),
          OfflinePackageAnswerOptionModel(
            answerOptionId: 'a2',
            stableKey: 'B',
            defaultSortOrder: 2,
            answerText: 'Option B',
          ),
        ],
      ),
      OfflinePackageQuestionModel(
        questionId: 'q2',
        sortOrder: 2,
        questionText: 'Question 2',
        questionType: 'single_choice',
        points: 1,
        randomizeAnswerOptions: randomizeAnswerOptions,
        scoringPolicy: 'strict',
        supportsMultipleCorrectAnswers: false,
        correctAnswerBlob: 'blob',
        answerOptions: [
          OfflinePackageAnswerOptionModel(
            answerOptionId: 'a3',
            stableKey: 'A',
            defaultSortOrder: 1,
            answerText: 'Option A',
          ),
          OfflinePackageAnswerOptionModel(
            answerOptionId: 'a4',
            stableKey: 'B',
            defaultSortOrder: 2,
            answerText: 'Option B',
          ),
        ],
      ),
    ],
    mediaAssets: const [],
    entitlements: const OfflineEntitlementsModel(canDownloadOffline: true),
  );
}
