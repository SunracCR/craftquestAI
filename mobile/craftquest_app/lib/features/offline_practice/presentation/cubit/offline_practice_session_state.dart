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
    this.startedAt,
    this.finishedAt,
    this.finishResult,
    this.reviewQuestions = const [],
    this.errorMessage,
  });

  final OfflinePracticeSessionStatus status;
  final OfflineQuizPackageModel? quiz;
  final int currentIndex;
  final Map<String, Set<String>> selections;
  final Map<String, OfflineAnswerKeyModel> answerKeyByQuestion;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final OfflineLocalFinishResultModel? finishResult;
  final List<OfflineReviewQuestionModel> reviewQuestions;
  final String? errorMessage;

  OfflinePackageQuestionModel? get currentQuestion {
    final questions = quiz?.questions ?? const [];
    if (currentIndex < 0 || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  int get totalQuestions => quiz?.questions.length ?? 0;

  int get answeredCount =>
      selections.values.where((selected) => selected.isNotEmpty).length;

  OfflinePracticeSessionState copyWith({
    OfflinePracticeSessionStatus? status,
    OfflineQuizPackageModel? quiz,
    int? currentIndex,
    Map<String, Set<String>>? selections,
    Map<String, OfflineAnswerKeyModel>? answerKeyByQuestion,
    DateTime? startedAt,
    DateTime? finishedAt,
    OfflineLocalFinishResultModel? finishResult,
    List<OfflineReviewQuestionModel>? reviewQuestions,
    String? errorMessage,
  }) {
    return OfflinePracticeSessionState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      selections: selections ?? this.selections,
      answerKeyByQuestion: answerKeyByQuestion ?? this.answerKeyByQuestion,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      finishResult: finishResult ?? this.finishResult,
      reviewQuestions: reviewQuestions ?? this.reviewQuestions,
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
        startedAt,
        finishedAt,
        finishResult,
        reviewQuestions,
        errorMessage,
      ];
}
