import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:equatable/equatable.dart';

enum AiGenerationProgressStatus {
  initial,
  polling,
  failed,
  retrying,
  completed,
}

/// Navigation target emitted when the job finishes successfully.
class AiGenerationCompletionTarget extends Equatable {
  const AiGenerationCompletionTarget({
    required this.quizTitle,
    this.quizId,
    this.importedQuestionCount,
  });

  final String? quizId;
  final String quizTitle;
  final int? importedQuestionCount;

  @override
  List<Object?> get props => [quizId, quizTitle, importedQuestionCount];
}

class AiGenerationProgressState extends Equatable {
  const AiGenerationProgressState({
    this.status = AiGenerationProgressStatus.initial,
    this.job,
    this.showLongRunningHint = false,
    this.failureMessage,
    this.failureDetail,
    this.completionTarget,
  });

  final AiGenerationProgressStatus status;
  final AiJobModel? job;
  final bool showLongRunningHint;
  final String? failureMessage;
  final String? failureDetail;
  final AiGenerationCompletionTarget? completionTarget;

  bool get isPolling =>
      status == AiGenerationProgressStatus.polling ||
      status == AiGenerationProgressStatus.initial;

  bool get isFailed => status == AiGenerationProgressStatus.failed;

  bool get isRetrying => status == AiGenerationProgressStatus.retrying;

  AiGenerationProgressState copyWith({
    AiGenerationProgressStatus? status,
    AiJobModel? job,
    bool clearJob = false,
    bool? showLongRunningHint,
    String? failureMessage,
    String? failureDetail,
    bool clearFailure = false,
    AiGenerationCompletionTarget? completionTarget,
    bool clearCompletion = false,
  }) {
    return AiGenerationProgressState(
      status: status ?? this.status,
      job: clearJob ? null : (job ?? this.job),
      showLongRunningHint: showLongRunningHint ?? this.showLongRunningHint,
      failureMessage:
          clearFailure ? null : (failureMessage ?? this.failureMessage),
      failureDetail:
          clearFailure ? null : (failureDetail ?? this.failureDetail),
      completionTarget: clearCompletion
          ? null
          : (completionTarget ?? this.completionTarget),
    );
  }

  @override
  List<Object?> get props => [
        status,
        job,
        showLongRunningHint,
        failureMessage,
        failureDetail,
        completionTarget,
      ];
}
