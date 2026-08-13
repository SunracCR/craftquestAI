import 'dart:async';

import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_crypto.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_local_grader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_order_generator.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_session_checkpoint_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class OfflinePracticeSessionCubit extends Cubit<OfflinePracticeSessionState> {
  OfflinePracticeSessionCubit({
    required OfflinePackageRepository packageRepository,
    required OfflineSyncRepository syncRepository,
    required OfflineSessionCheckpointRepository checkpointRepository,
    required String quizId,
    this.showElapsedTimer = false,
    this.randomizeQuestions,
  })  : _packageRepository = packageRepository,
        _syncRepository = syncRepository,
        _checkpointRepository = checkpointRepository,
        _quizId = quizId,
        super(const OfflinePracticeSessionState());

  final OfflinePackageRepository _packageRepository;
  final OfflineSyncRepository _syncRepository;
  final OfflineSessionCheckpointRepository _checkpointRepository;
  final String _quizId;
  final bool showElapsedTimer;
  final bool? randomizeQuestions;
  final _uuid = const Uuid();

  OfflineSessionOrder _generateSessionOrder(OfflineQuizPackageModel quiz) =>
      generateFreshOrder(
        quiz,
        randomizeQuestionsOverride: randomizeQuestions,
      );

  Future<void> load() async {
    emit(state.copyWith(status: OfflinePracticeSessionStatus.loading));
    try {
      final quiz = await _packageRepository.loadStoredQuizContent(_quizId);
      if (quiz == null) {
        emit(
          state.copyWith(
            status: OfflinePracticeSessionStatus.error,
            errorMessage: 'Quiz offline no encontrado.',
          ),
        );
        return;
      }

      if (quiz.packageKeyBase64.isEmpty) {
        emit(
          state.copyWith(
            status: OfflinePracticeSessionStatus.error,
            errorMessage: 'Clave offline no disponible.',
          ),
        );
        return;
      }

      final missingAnswerKey = quiz.questions.any((q) => !q.hasAnswerKeyBlob);
      if (missingAnswerKey) {
        emit(
          state.copyWith(
            status: OfflinePracticeSessionStatus.error,
            errorMessage: 'offline_download_needs_update',
          ),
        );
        return;
      }

      final answerKeys = <String, OfflineAnswerKeyModel>{};
      for (final question in quiz.questions) {
        answerKeys[question.questionId] = await OfflineCrypto.decryptAnswerKey(
          packageKeyBase64: quiz.packageKeyBase64,
          answerKeyBlob: question.answerKeyBlob!,
        );
      }

      final freshOrder = _generateSessionOrder(quiz);

      var pendingCheckpoint = await _checkpointRepository.loadCheckpoint(_quizId);
      if (pendingCheckpoint != null &&
          pendingCheckpoint.contentVersion != quiz.contentVersion) {
        await _checkpointRepository.clearCheckpoint(_quizId);
        pendingCheckpoint = null;
      }

      if (pendingCheckpoint != null &&
          !isValidOrderForQuiz(
            order: OfflineSessionOrder(
              questionOrder: pendingCheckpoint.questionOrder,
              answerOrderByQuestion: pendingCheckpoint.answerOrderByQuestion,
            ),
            quiz: quiz,
          )) {
        await _checkpointRepository.clearCheckpoint(_quizId);
        pendingCheckpoint = null;
      }

      final hasPendingCheckpoint =
          pendingCheckpoint != null && pendingCheckpoint.hasProgress;

      emit(
        state.copyWith(
          status: OfflinePracticeSessionStatus.ready,
          quiz: quiz,
          answerKeyByQuestion: answerKeys,
          questionOrder: freshOrder.questionOrder,
          answerOrderByQuestion: freshOrder.answerOrderByQuestion,
          startedAt: hasPendingCheckpoint ? null : DateTime.now().toUtc(),
          pendingCheckpoint: hasPendingCheckpoint ? pendingCheckpoint : null,
          clearPendingCheckpoint: !hasPendingCheckpoint,
        ),
      );

      if (!hasPendingCheckpoint) {
        unawaited(_persistCheckpoint());
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: OfflinePracticeSessionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void applyCheckpoint() {
    final checkpoint = state.pendingCheckpoint;
    if (checkpoint == null) {
      return;
    }

    emit(
      state.copyWith(
        currentIndex: checkpoint.currentIndex,
        selections: checkpoint.selections,
        startedAt: checkpoint.startedAt,
        questionOrder: checkpoint.questionOrder,
        answerOrderByQuestion: checkpoint.answerOrderByQuestion,
        clearPendingCheckpoint: true,
      ),
    );
  }

  Future<void> discardCheckpoint() async {
    await _checkpointRepository.clearCheckpoint(_quizId);
    final quiz = state.quiz;
    if (quiz == null) {
      return;
    }

    final freshOrder = _generateSessionOrder(quiz);
    emit(
      state.copyWith(
        currentIndex: 0,
        selections: const {},
        startedAt: DateTime.now().toUtc(),
        questionOrder: freshOrder.questionOrder,
        answerOrderByQuestion: freshOrder.answerOrderByQuestion,
        clearPendingCheckpoint: true,
      ),
    );
    unawaited(_persistCheckpoint());
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= state.totalQuestions) {
      return;
    }
    emit(
      state.copyWith(
        currentIndex: index,
        status: OfflinePracticeSessionStatus.answering,
      ),
    );
    unawaited(_persistCheckpoint());
  }

  void toggleSelection({
    required String questionId,
    required String answerOptionId,
    required bool supportsMultiple,
  }) {
    final current = Set<String>.from(state.selections[questionId] ?? {});
    if (supportsMultiple) {
      if (current.contains(answerOptionId)) {
        current.remove(answerOptionId);
      } else {
        current.add(answerOptionId);
      }
    } else {
      current
        ..clear()
        ..add(answerOptionId);
    }

    final selections = Map<String, Set<String>>.from(state.selections)
      ..[questionId] = current;
    emit(state.copyWith(selections: selections));
    unawaited(_persistCheckpoint());
  }

  Future<void> answerAndContinue() async {
    final question = state.currentQuestion;
    if (question == null) {
      return;
    }

    final selected = state.selections[question.questionId] ?? {};
    if (selected.isEmpty) {
      return;
    }

    if (state.currentIndex + 1 >= state.totalQuestions) {
      await finishSession();
      return;
    }

    goToQuestion(state.currentIndex + 1);
  }

  Future<void> finishSession() async {
    final quiz = state.quiz;
    if (quiz == null || state.startedAt == null) {
      return;
    }

    final finishedAt = DateTime.now().toUtc();
    final clientSessionId = _uuid.v4();
    final correctAnswersByQuestion = {
      for (final entry in state.answerKeyByQuestion.entries)
        entry.key: entry.value.correctAnswerOptionIds,
    };

    final orderedQuestions = _orderedQuestions(quiz);

    final result = OfflineLocalGrader.finishSession(
      clientSessionId: clientSessionId,
      questions: orderedQuestions,
      selections: state.selections,
      correctAnswersByQuestion: correctAnswersByQuestion,
    );

    final reviewQuestions = _buildReviewQuestions(
      quiz: quiz,
      selections: state.selections,
      answerKeyByQuestion: state.answerKeyByQuestion,
    );

    final answers = orderedQuestions
        .map(
          (question) => OfflineSyncAnswerModel(
            questionId: question.questionId,
            selectedAnswerOptionIds:
                (state.selections[question.questionId] ?? {}).toList(),
            answeredAt: finishedAt,
          ),
        )
        .toList();

    await _syncRepository.enqueueFinishedSession(
      clientSessionId: clientSessionId,
      quizId: quiz.quizId,
      contentVersion: quiz.contentVersion,
      startedAt: state.startedAt!,
      finishedAt: finishedAt,
      showElapsedTimer: showElapsedTimer,
      localScoreObtained: result.scoreObtained,
      localScorePossible: result.scorePossible,
      answers: answers,
    );

    await _checkpointRepository.clearCheckpoint(_quizId);

    emit(
      state.copyWith(
        status: OfflinePracticeSessionStatus.finished,
        finishedAt: finishedAt,
        finishResult: result,
        reviewQuestions: reviewQuestions,
      ),
    );
  }

  Future<void> _persistCheckpoint() async {
    final quiz = state.quiz;
    final startedAt = state.startedAt;
    if (quiz == null || startedAt == null || state.questionOrder.isEmpty) {
      return;
    }

    try {
      await _checkpointRepository.saveCheckpoint(
        quizId: quiz.quizId,
        contentVersion: quiz.contentVersion,
        currentIndex: state.currentIndex,
        selections: state.selections,
        startedAt: startedAt,
        questionOrder: state.questionOrder,
        answerOrderByQuestion: state.answerOrderByQuestion,
      );
    } catch (_) {
      // Best-effort persistence; session can continue in memory.
    }
  }

  List<OfflinePackageQuestionModel> _orderedQuestions(
    OfflineQuizPackageModel quiz,
  ) {
    if (state.questionOrder.isEmpty) {
      return List<OfflinePackageQuestionModel>.from(quiz.questions)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final questionsById = {
      for (final question in quiz.questions) question.questionId: question,
    };
    return state.questionOrder
        .map((id) => questionsById[id])
        .whereType<OfflinePackageQuestionModel>()
        .toList();
  }

  List<OfflineReviewQuestionModel> _buildReviewQuestions({
    required OfflineQuizPackageModel quiz,
    required Map<String, Set<String>> selections,
    required Map<String, OfflineAnswerKeyModel> answerKeyByQuestion,
  }) {
    final reviewQuestions = <OfflineReviewQuestionModel>[];

    for (final question in _orderedQuestions(quiz)) {
      final answerKey = answerKeyByQuestion[question.questionId];
      if (answerKey == null) {
        continue;
      }

      final selected = selections[question.questionId] ?? {};
      final correctIds = answerKey.correctAnswerOptionIds.toSet();
      final feedback = OfflineLocalGrader.gradeQuestion(
        question: question,
        selectedIds: selected,
        correctIds: answerKey.correctAnswerOptionIds,
      );

      final displayOptions = state.orderedAnswerOptions(question);

      final reviewOptions = <OfflineReviewAnswerOptionModel>[];
      for (var i = 0; i < displayOptions.length; i++) {
        final option = displayOptions[i];
        reviewOptions.add(
          OfflineReviewAnswerOptionModel(
            answerOptionId: option.answerOptionId,
            stableKey: option.stableKey,
            defaultSortOrder: option.defaultSortOrder,
            answerText: option.answerText,
            mediaAssetId: option.mediaAssetId,
            wasSelected: selected.contains(option.answerOptionId),
            isCorrect: correctIds.contains(option.answerOptionId),
            displayLabel: String.fromCharCode(65 + i),
          ),
        );
      }

      reviewQuestions.add(
        OfflineReviewQuestionModel(
          questionId: question.questionId,
          sortOrder: question.sortOrder,
          questionText: question.questionText,
          questionMediaAssetId: question.questionMediaAssetId,
          points: question.points,
          supportsMultipleCorrectAnswers:
              question.supportsMultipleCorrectAnswers,
          answerOptions: reviewOptions,
          selectedAnswerOptionIds: selected,
          isCorrect: feedback.isCorrect,
          pointsAwarded: feedback.pointsAwarded,
          justificationText: answerKey.justificationText,
          justificationSources: answerKey.justificationSources,
        ),
      );
    }

    return reviewQuestions;
  }
}
