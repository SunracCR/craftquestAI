import 'package:craftquest_app/core/utils/assignment_dates.dart';

class StudentClassSummaryModel {
  const StudentClassSummaryModel({
    required this.classId,
    required this.name,
    required this.teacherDisplayName,
    required this.activeAssignmentCount,
    this.description,
  });

  factory StudentClassSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentClassSummaryModel(
      classId: json['classId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      teacherDisplayName: json['teacherDisplayName'] as String,
      activeAssignmentCount: json['activeAssignmentCount'] as int? ?? 0,
    );
  }

  final String classId;
  final String name;
  final String? description;
  final String teacherDisplayName;
  final int activeAssignmentCount;
}

class StudentAssignmentModel {
  const StudentAssignmentModel({
    required this.assignmentId,
    required this.classId,
    required this.className,
    required this.quizId,
    required this.title,
    required this.quizTitle,
    required this.status,
    required this.myAttemptCount,
    required this.teacherDisplayName,
    required this.createdAt,
    this.instructions,
    this.startsAt,
    this.dueAt,
    this.maxAttempts,
  });

  factory StudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentModel(
      assignmentId: json['assignmentId'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      quizTitle: json['quizTitle'] as String,
      instructions: json['instructions'] as String?,
      status: json['status'] as String,
      startsAt: json['startsAt'] != null
          ? AssignmentDates.parseFromApi(json['startsAt'] as String)
          : null,
      dueAt: json['dueAt'] != null
          ? AssignmentDates.parseFromApi(json['dueAt'] as String)
          : null,
      maxAttempts: json['maxAttempts'] as int?,
      myAttemptCount: json['myAttemptCount'] as int? ?? 0,
      teacherDisplayName: json['teacherDisplayName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String assignmentId;
  final String classId;
  final String className;
  final String quizId;
  final String title;
  final String quizTitle;
  final String? instructions;
  final String status;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final int? maxAttempts;
  final int myAttemptCount;
  final String teacherDisplayName;
  final DateTime createdAt;

  bool get isActive => status == 'active';

  bool get isNotYetOpen {
    if (!isActive) return false;
    return AssignmentDates.isNotYetOpen(startsAt);
  }

  bool get isPastDue {
    if (!isActive) return false;
    return AssignmentDates.isPastDue(dueAt);
  }

  bool get hasReachedMaxAttempts =>
      maxAttempts != null && myAttemptCount >= maxAttempts!;

  bool get isOpen {
    if (!isActive) return false;
    if (isNotYetOpen) return false;
    if (isPastDue) return false;
    if (hasReachedMaxAttempts) return false;
    return true;
  }
}

class StudentAssignmentAttemptModel {
  const StudentAssignmentAttemptModel({
    required this.practiceSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.status,
    required this.startedAt,
    required this.canViewDetailedReview,
    required this.assignmentShowCorrectAnswersMode,
    this.finishedAt,
    this.durationSeconds,
    this.showElapsedTimer = false,
    this.assignmentDueAt,
  });

  factory StudentAssignmentAttemptModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentAttemptModel(
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
      canViewDetailedReview: json['canViewDetailedReview'] as bool? ?? false,
      assignmentShowCorrectAnswersMode:
          json['assignmentShowCorrectAnswersMode'] as String? ?? 'teacher_only',
      assignmentDueAt: json['assignmentDueAt'] != null
          ? AssignmentDates.parseFromApi(json['assignmentDueAt'] as String)
          : null,
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
  final bool canViewDetailedReview;
  final String assignmentShowCorrectAnswersMode;
  final DateTime? assignmentDueAt;

  DateTime get sortDate => finishedAt ?? startedAt;
}

class StudentAssignmentSummaryModel {
  const StudentAssignmentSummaryModel({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.finishedAttempts,
    this.bestPercentage,
    this.lastPercentage,
    this.averagePercentage,
    this.scoreTrend,
    required this.attemptTrend,
    required this.hardQuestionsForMe,
    required this.canViewDetailedReview,
    required this.assignmentShowCorrectAnswersMode,
    this.assignmentDueAt,
  });

  factory StudentAssignmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentSummaryModel(
      assignmentId: json['assignmentId'] as String,
      assignmentTitle: json['assignmentTitle'] as String,
      finishedAttempts: json['finishedAttempts'] as int? ?? 0,
      bestPercentage: (json['bestPercentage'] as num?)?.toDouble(),
      lastPercentage: (json['lastPercentage'] as num?)?.toDouble(),
      averagePercentage: (json['averagePercentage'] as num?)?.toDouble(),
      scoreTrend: (json['scoreTrend'] as num?)?.toDouble(),
      attemptTrend: (json['attemptTrend'] as List<dynamic>? ?? [])
          .map((e) =>
              AssignmentAttemptTrendModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hardQuestionsForMe: (json['hardQuestionsForMe'] as List<dynamic>? ?? [])
          .map((e) => StudentQuestionSummaryModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      canViewDetailedReview: json['canViewDetailedReview'] as bool? ?? false,
      assignmentShowCorrectAnswersMode:
          json['assignmentShowCorrectAnswersMode'] as String? ?? 'teacher_only',
      assignmentDueAt: json['assignmentDueAt'] != null
          ? AssignmentDates.parseFromApi(json['assignmentDueAt'] as String)
          : null,
    );
  }

  final String assignmentId;
  final String assignmentTitle;
  final int finishedAttempts;
  final double? bestPercentage;
  final double? lastPercentage;
  final double? averagePercentage;
  final double? scoreTrend;
  final List<AssignmentAttemptTrendModel> attemptTrend;
  final List<StudentQuestionSummaryModel> hardQuestionsForMe;
  final bool canViewDetailedReview;
  final String assignmentShowCorrectAnswersMode;
  final DateTime? assignmentDueAt;
}

class AssignmentAttemptTrendModel {
  const AssignmentAttemptTrendModel({
    required this.attemptNumber,
    required this.percentage,
    required this.finishedAt,
    required this.practiceSessionId,
  });

  factory AssignmentAttemptTrendModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttemptTrendModel(
      attemptNumber: json['attemptNumber'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      practiceSessionId: json['practiceSessionId'] as String,
    );
  }

  final int attemptNumber;
  final double percentage;
  final DateTime finishedAt;
  final String practiceSessionId;
}

class StudentQuestionSummaryModel {
  const StudentQuestionSummaryModel({
    required this.questionId,
    required this.questionText,
    required this.attemptsCount,
    required this.incorrectCount,
  });

  factory StudentQuestionSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentQuestionSummaryModel(
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
    );
  }

  final String questionId;
  final String questionText;
  final int attemptsCount;
  final int incorrectCount;
}
