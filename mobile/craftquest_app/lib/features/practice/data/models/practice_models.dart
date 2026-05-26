import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';

class PracticeActiveSessionModel {
  const PracticeActiveSessionModel({
    required this.practiceSessionId,
    required this.quizId,
    required this.currentQuestionIndex,
    required this.answeredCount,
    required this.totalQuestions,
  });

  factory PracticeActiveSessionModel.fromJson(Map<String, dynamic> json) {
    return PracticeActiveSessionModel(
      practiceSessionId: json['practiceSessionId'] as String,
      quizId: json['quizId'] as String,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      answeredCount: json['answeredCount'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
    );
  }

  final String practiceSessionId;
  final String quizId;
  final int currentQuestionIndex;
  final int answeredCount;
  final int totalQuestions;
}

class PracticeSessionModel {
  const PracticeSessionModel({
    required this.practiceSessionId,
    required this.quizId,
    required this.status,
    required this.questions,
    this.showElapsedTimer = false,
    this.currentQuestionIndex = 0,
    this.elapsedSecondsBeforePause = 0,
    this.answeredCount = 0,
    this.totalQuestions = 0,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>)
        .map(
          (e) => PracticeQuestionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return PracticeSessionModel(
      practiceSessionId: json['practiceSessionId'] as String,
      quizId: json['quizId'] as String,
      status: json['status'] as String,
      showElapsedTimer: json['showElapsedTimer'] as bool? ?? false,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      elapsedSecondsBeforePause:
          json['elapsedSecondsBeforePause'] as int? ?? 0,
      answeredCount: json['answeredCount'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? questions.length,
      questions: questions,
    );
  }

  final String practiceSessionId;
  final String quizId;
  final String status;
  final bool showElapsedTimer;
  final int currentQuestionIndex;
  final int elapsedSecondsBeforePause;
  final int answeredCount;
  final int totalQuestions;
  final List<PracticeQuestionModel> questions;
}

class PracticeQuestionModel {
  const PracticeQuestionModel({
    required this.practiceQuestionSnapshotId,
    required this.questionId,
    required this.displayOrder,
    required this.questionText,
    required this.questionType,
    this.questionMediaUrl,
    this.answerStatus = 'unanswered',
    this.selectedAnswerOptionIds = const [],
    required this.answers,
  });

  factory PracticeQuestionModel.fromJson(Map<String, dynamic> json) {
    return PracticeQuestionModel(
      practiceQuestionSnapshotId: json['practiceQuestionSnapshotId'] as String,
      questionId: json['questionId'] as String,
      displayOrder: json['displayOrder'] as int,
      questionText: json['questionText'] as String,
      questionType: json['questionType'] as String,
      questionMediaUrl: json['questionMediaUrl'] as String?,
      answerStatus: json['answerStatus'] as String? ?? 'unanswered',
      selectedAnswerOptionIds:
          (json['selectedAnswerOptionIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      answers: (json['answers'] as List<dynamic>)
          .map(
            (e) =>
                PracticeAnswerOptionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String practiceQuestionSnapshotId;
  final String questionId;
  final int displayOrder;
  final String questionText;
  final String questionType;
  final String? questionMediaUrl;
  final String answerStatus;
  final List<String> selectedAnswerOptionIds;
  final List<PracticeAnswerOptionModel> answers;
}

class PracticeAnswerOptionModel {
  const PracticeAnswerOptionModel({
    required this.answerOptionId,
    required this.displayOrder,
    required this.displayLabel,
    this.text,
    this.mediaUrl,
  });

  factory PracticeAnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return PracticeAnswerOptionModel(
      answerOptionId: json['answerOptionId'] as String,
      displayOrder: json['displayOrder'] as int,
      displayLabel: json['displayLabel'] as String,
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  final String answerOptionId;
  final int displayOrder;
  final String displayLabel;
  final String? text;
  final String? mediaUrl;
}

class MyPracticeAttemptModel {
  const MyPracticeAttemptModel({
    required this.practiceSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.showElapsedTimer = false,
  });

  factory MyPracticeAttemptModel.fromJson(Map<String, dynamic> json) {
    return MyPracticeAttemptModel(
      practiceSessionId: json['practiceSessionId'] as String,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int?,
      showElapsedTimer: json['showElapsedTimer'] as bool? ?? false,
    );
  }

  final String practiceSessionId;
  final double scoreObtained;
  final double scorePossible;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final bool showElapsedTimer;

  DateTime get sortDate => finishedAt ?? startedAt;
}

class MyQuizPracticeAnalyticsModel {
  const MyQuizPracticeAnalyticsModel({
    required this.quizId,
    required this.finishedAttempts,
    this.averagePercentage,
    this.bestPercentage,
    required this.questions,
  });

  factory MyQuizPracticeAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MyQuizPracticeAnalyticsModel(
      quizId: json['quizId'] as String,
      finishedAttempts: json['finishedAttempts'] as int? ?? 0,
      averagePercentage: (json['averagePercentage'] as num?)?.toDouble(),
      bestPercentage: (json['bestPercentage'] as num?)?.toDouble(),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String quizId;
  final int finishedAttempts;
  final double? averagePercentage;
  final double? bestPercentage;
  final List<QuestionAnalyticsModel> questions;
}

class PracticeSessionResultModel {
  const PracticeSessionResultModel({
    required this.practiceSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.omittedAnswers,
    this.canViewDetailedReview = true,
    this.assignmentShowCorrectAnswersMode,
    this.assignmentDueAt,
    this.scoreTrendVsPrevious,
    this.questionsToReview = const [],
  });

  factory PracticeSessionResultModel.fromJson(Map<String, dynamic> json) {
    return PracticeSessionResultModel(
      practiceSessionId: json['practiceSessionId'] as String,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      correctAnswers: json['correctAnswers'] as int,
      incorrectAnswers: json['incorrectAnswers'] as int,
      omittedAnswers: json['omittedAnswers'] as int,
      canViewDetailedReview: json['canViewDetailedReview'] as bool? ?? true,
      assignmentShowCorrectAnswersMode:
          json['assignmentShowCorrectAnswersMode'] as String?,
      assignmentDueAt: json['assignmentDueAt'] != null
          ? DateTime.parse(json['assignmentDueAt'] as String)
          : null,
      scoreTrendVsPrevious: (json['scoreTrendVsPrevious'] as num?)?.toDouble(),
      questionsToReview: (json['questionsToReview'] as List<dynamic>? ?? [])
          .map((e) =>
              PracticeWeakQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String practiceSessionId;
  final double scoreObtained;
  final double scorePossible;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int omittedAnswers;
  final bool canViewDetailedReview;
  final String? assignmentShowCorrectAnswersMode;
  final double? scoreTrendVsPrevious;
  final List<PracticeWeakQuestionModel> questionsToReview;
  final DateTime? assignmentDueAt;
}

class PracticeWeakQuestionModel {
  const PracticeWeakQuestionModel({
    required this.practiceQuestionSnapshotId,
    required this.questionId,
    required this.questionText,
    required this.displayOrder,
  });

  factory PracticeWeakQuestionModel.fromJson(Map<String, dynamic> json) {
    return PracticeWeakQuestionModel(
      practiceQuestionSnapshotId:
          json['practiceQuestionSnapshotId'] as String,
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  final String practiceQuestionSnapshotId;
  final String questionId;
  final String questionText;
  final int displayOrder;
}
