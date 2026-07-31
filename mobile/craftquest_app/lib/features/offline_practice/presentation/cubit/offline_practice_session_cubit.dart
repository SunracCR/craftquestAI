import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_crypto.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_local_grader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class OfflinePracticeSessionCubit extends Cubit<OfflinePracticeSessionState> {
  OfflinePracticeSessionCubit({
    required OfflinePackageRepository packageRepository,
    required OfflineSyncRepository syncRepository,
    required String quizId,
    this.showElapsedTimer = false,
  })  : _packageRepository = packageRepository,
        _syncRepository = syncRepository,
        _quizId = quizId,
        super(const OfflinePracticeSessionState());

  final OfflinePackageRepository _packageRepository;
  final OfflineSyncRepository _syncRepository;
  final String _quizId;
  final bool showElapsedTimer;
  final _uuid = const Uuid();

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

      emit(
        state.copyWith(
          status: OfflinePracticeSessionStatus.ready,
          quiz: quiz,
          answerKeyByQuestion: answerKeys,
          startedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OfflinePracticeSessionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
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

    final result = OfflineLocalGrader.finishSession(
      clientSessionId: clientSessionId,
      questions: quiz.questions,
      selections: state.selections,
      correctAnswersByQuestion: correctAnswersByQuestion,
    );

    final reviewQuestions = _buildReviewQuestions(
      quiz: quiz,
      selections: state.selections,
      answerKeyByQuestion: state.answerKeyByQuestion,
    );

    final answers = quiz.questions
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

    emit(
      state.copyWith(
        status: OfflinePracticeSessionStatus.finished,
        finishedAt: finishedAt,
        finishResult: result,
        reviewQuestions: reviewQuestions,
      ),
    );
  }

  List<OfflineReviewQuestionModel> _buildReviewQuestions({
    required OfflineQuizPackageModel quiz,
    required Map<String, Set<String>> selections,
    required Map<String, OfflineAnswerKeyModel> answerKeyByQuestion,
  }) {
    final reviewQuestions = <OfflineReviewQuestionModel>[];

    for (final question in quiz.questions) {
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

      final displayOptions = question.answerOptions
          .where((o) => !OfflineLocalGrader.isQuestionImageStem(o.stableKey))
          .toList()
        ..sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));

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

    reviewQuestions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return reviewQuestions;
  }
}
