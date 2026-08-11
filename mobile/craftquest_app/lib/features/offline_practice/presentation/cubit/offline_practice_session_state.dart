import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:equatable/equatable.dart';

enum OfflinePracticeSessionStatus {
  loading,
  ready,
  answering,
  finished,
  error,
}

class OfflinePracticeSessionState extends Equatable {
  const OfflinePracticeSessionState({
    this.status = OfflinePracticeSessionStatus.loading,
    this.quiz,
    this.currentIndex = 0,
    this.selections = const {},
    this.answerKeyByQuestion = const {},
    this.questionOrder = const [],
    this.answerOrderByQuestion = const {},
    this.startedAt,
    this.finishedAt,
    this.finishResult,
    this.reviewQuestions = const [],
    this.pendingCheckpoint,
    this.errorMessage,
  });

  final OfflinePracticeSessionStatus status;
  final OfflineQuizPackageModel? quiz;
  final int currentIndex;
  final Map<String, Set<String>> selections;
  final Map<String, OfflineAnswerKeyModel> answerKeyByQuestion;
  final List<String> questionOrder;
  final Map<String, List<String>> answerOrderByQuestion;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final OfflineLocalFinishResultModel? finishResult;
  final List<OfflineReviewQuestionModel> reviewQuestions;
  final OfflineSessionCheckpointModel? pendingCheckpoint;
  final String? errorMessage;

  OfflinePackageQuestionModel? get currentQuestion {
    if (quiz == null || questionOrder.isEmpty) {
      return null;
    }
    if (currentIndex < 0 || currentIndex >= questionOrder.length) {
      return null;
    }
    final questionId = questionOrder[currentIndex];
    for (final question in quiz!.questions) {
      if (question.questionId == questionId) {
        return question;
      }
    }
    return null;
  }

  int get totalQuestions => questionOrder.isNotEmpty
      ? questionOrder.length
      : (quiz?.questions.length ?? 0);

  int get answeredCount =>
      selections.values.where((selected) => selected.isNotEmpty).length;

  List<OfflinePackageAnswerOptionModel> orderedAnswerOptions(
    OfflinePackageQuestionModel question,
  ) {
    final orderedIds = answerOrderByQuestion[question.questionId];
    if (orderedIds == null || orderedIds.isEmpty) {
      return question.answerOptions.toList()
        ..sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));
    }

    final optionsById = {
      for (final option in question.answerOptions) option.answerOptionId: option,
    };
    return orderedIds
        .map((id) => optionsById[id])
        .whereType<OfflinePackageAnswerOptionModel>()
        .toList();
  }

  OfflinePracticeSessionState copyWith({
    OfflinePracticeSessionStatus? status,
    OfflineQuizPackageModel? quiz,
    int? currentIndex,
    Map<String, Set<String>>? selections,
    Map<String, OfflineAnswerKeyModel>? answerKeyByQuestion,
    List<String>? questionOrder,
    Map<String, List<String>>? answerOrderByQuestion,
    DateTime? startedAt,
    DateTime? finishedAt,
    OfflineLocalFinishResultModel? finishResult,
    List<OfflineReviewQuestionModel>? reviewQuestions,
    OfflineSessionCheckpointModel? pendingCheckpoint,
    bool clearPendingCheckpoint = false,
    String? errorMessage,
  }) {
    return OfflinePracticeSessionState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      selections: selections ?? this.selections,
      answerKeyByQuestion: answerKeyByQuestion ?? this.answerKeyByQuestion,
      questionOrder: questionOrder ?? this.questionOrder,
      answerOrderByQuestion:
          answerOrderByQuestion ?? this.answerOrderByQuestion,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      finishResult: finishResult ?? this.finishResult,
      reviewQuestions: reviewQuestions ?? this.reviewQuestions,
      pendingCheckpoint: clearPendingCheckpoint
          ? null
          : (pendingCheckpoint ?? this.pendingCheckpoint),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        quiz?.quizId,
        currentIndex,
        selections,
        answerKeyByQuestion,
        questionOrder,
        answerOrderByQuestion,
        startedAt,
        finishedAt,
        finishResult,
        reviewQuestions,
        pendingCheckpoint,
        errorMessage,
      ];
}
