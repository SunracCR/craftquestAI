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

      final correctAnswers = <String, List<String>>{};
      for (final question in quiz.questions) {
        correctAnswers[question.questionId] =
            await OfflineCrypto.decryptCorrectAnswerIds(
          packageKeyBase64: quiz.packageKeyBase64,
          correctAnswerBlob: question.correctAnswerBlob,
        );
      }

      emit(
        state.copyWith(
          status: OfflinePracticeSessionStatus.ready,
          quiz: quiz,
          correctAnswersByQuestion: correctAnswers,
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

  Future<void> submitCurrentQuestion() async {
    final question = state.currentQuestion;
    final quiz = state.quiz;
    if (question == null || quiz == null) {
      return;
    }

    final selected = state.selections[question.questionId] ?? {};
    if (selected.isEmpty) {
      return;
    }

    final correctIds =
        state.correctAnswersByQuestion[question.questionId] ?? const [];
    final feedback = OfflineLocalGrader.gradeQuestion(
      question: question,
      selectedIds: selected,
      correctIds: correctIds,
    );

    final feedbackMap =
        Map<String, OfflineQuestionFeedbackModel>.from(state.feedbackByQuestion)
          ..[question.questionId] = feedback;

    emit(
      state.copyWith(
        feedbackByQuestion: feedbackMap,
        status: OfflinePracticeSessionStatus.answering,
      ),
    );
  }

  Future<void> finishSession() async {
    final quiz = state.quiz;
    if (quiz == null || state.startedAt == null) {
      return;
    }

    final finishedAt = DateTime.now().toUtc();
    final clientSessionId = _uuid.v4();
    final result = OfflineLocalGrader.finishSession(
      clientSessionId: clientSessionId,
      questions: quiz.questions,
      selections: state.selections,
      correctAnswersByQuestion: state.correctAnswersByQuestion,
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
      ),
    );
  }
}
