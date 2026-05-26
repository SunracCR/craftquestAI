import 'package:craftquest_app/core/utils/assignment_dates.dart';

class AssignmentDetailModel {
  const AssignmentDetailModel({
    required this.assignmentId,
    required this.classId,
    required this.quizId,
    required this.title,
    this.instructions,
    required this.quizTitle,
    required this.status,
    required this.showCorrectAnswersMode,
    this.startsAt,
    this.dueAt,
    this.maxAttempts,
    required this.completedCount,
    required this.totalMembers,
    required this.createdAt,
    required this.attempts,
  });

  factory AssignmentDetailModel.fromJson(Map<String, dynamic> json) {
    return AssignmentDetailModel(
      assignmentId: json['assignmentId'] as String,
      classId: json['classId'] as String,
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String?,
      quizTitle: json['quizTitle'] as String,
      status: json['status'] as String? ?? 'active',
      showCorrectAnswersMode:
          json['showCorrectAnswersMode'] as String? ?? 'after_due_date',
      startsAt: json['startsAt'] != null
          ? AssignmentDates.parseFromApi(json['startsAt'] as String)
          : null,
      dueAt: json['dueAt'] != null
          ? AssignmentDates.parseFromApi(json['dueAt'] as String)
          : null,
      maxAttempts: json['maxAttempts'] as int?,
      completedCount: json['completedCount'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attempts: (json['attempts'] as List<dynamic>? ?? [])
          .map((e) => AssignmentAttemptModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String assignmentId;
  final String classId;
  final String quizId;
  final String title;
  final String? instructions;
  final String quizTitle;
  final String status;
  final String showCorrectAnswersMode;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final int? maxAttempts;
  final int completedCount;
  final int totalMembers;
  final DateTime createdAt;
  final List<AssignmentAttemptModel> attempts;

  double get completionRate =>
      totalMembers > 0 ? completedCount / totalMembers : 0.0;
}

class AssignmentAttemptModel {
  const AssignmentAttemptModel({
    required this.practiceSessionId,
    required this.studentUserId,
    required this.studentName,
    this.studentAvatarId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.percentage,
    required this.finishedAt,
  });

  factory AssignmentAttemptModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttemptModel(
      practiceSessionId: json['practiceSessionId'] as String,
      studentUserId: json['studentUserId'] as String,
      studentName: json['studentName'] as String,
      studentAvatarId: json['studentAvatarId'] as String?,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      percentage: json['percentage'] as int? ?? 0,
      finishedAt: DateTime.parse(json['finishedAt'] as String),
    );
  }

  final String practiceSessionId;
  final String studentUserId;
  final String studentName;
  final String? studentAvatarId;
  final double scoreObtained;
  final double scorePossible;
  final int percentage;
  final DateTime finishedAt;
}

class AssignmentCompletionModel {
  const AssignmentCompletionModel({
    required this.completedCount,
    required this.totalMembers,
    required this.members,
  });

  factory AssignmentCompletionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentCompletionModel(
      completedCount: json['completedCount'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) =>
              AssignmentMemberProgressModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int completedCount;
  final int totalMembers;
  final List<AssignmentMemberProgressModel> members;

  double get completionRate =>
      totalMembers > 0 ? completedCount / totalMembers : 0.0;
}

class AssignmentMemberProgressModel {
  const AssignmentMemberProgressModel({
    required this.userId,
    required this.displayName,
    this.avatarId,
    required this.hasCompleted,
    this.bestScorePercent,
    required this.attemptCount,
  });

  factory AssignmentMemberProgressModel.fromJson(Map<String, dynamic> json) {
    return AssignmentMemberProgressModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarId: json['avatarId'] as String?,
      hasCompleted: json['hasCompleted'] as bool? ?? false,
      bestScorePercent: json['bestScorePercent'] as int?,
      attemptCount: json['attemptCount'] as int? ?? 0,
    );
  }

  final String userId;
  final String displayName;
  final String? avatarId;
  final bool hasCompleted;
  final int? bestScorePercent;
  final int attemptCount;
}

class AssignmentAnalyticsModel {
  const AssignmentAnalyticsModel({
    required this.assignmentId,
    required this.classId,
    required this.title,
    required this.className,
    required this.totalMembers,
    required this.uniqueStudentsCompleted,
    required this.completionRate,
    required this.averageScore,
    this.medianScore,
    required this.totalSessions,
    required this.students,
    required this.hardQuestions,
    required this.scoreDistribution,
  });

  factory AssignmentAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAnalyticsModel(
      assignmentId: json['assignmentId'] as String,
      classId: json['classId'] as String,
      title: json['title'] as String,
      className: json['className'] as String,
      totalMembers: json['totalMembers'] as int? ?? 0,
      uniqueStudentsCompleted:
          json['uniqueStudentsCompleted'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      medianScore: (json['medianScore'] as num?)?.toDouble(),
      totalSessions: json['totalSessions'] as int? ?? 0,
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => AssignmentStudentProgressModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      hardQuestions: (json['hardQuestions'] as List<dynamic>? ?? [])
          .map((e) => AssignmentQuestionDifficultyModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      scoreDistribution: (json['scoreDistribution'] as List<dynamic>? ?? [])
          .map((e) => ScoreDistributionBucketModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String assignmentId;
  final String classId;
  final String title;
  final String className;
  final int totalMembers;
  final int uniqueStudentsCompleted;
  final double completionRate;
  final double averageScore;
  final double? medianScore;
  final int totalSessions;
  final List<AssignmentStudentProgressModel> students;
  final List<AssignmentQuestionDifficultyModel> hardQuestions;
  final List<ScoreDistributionBucketModel> scoreDistribution;
}

class AssignmentStudentProgressModel {
  const AssignmentStudentProgressModel({
    required this.userId,
    required this.displayName,
    this.avatarId,
    required this.hasCompleted,
    required this.attemptCount,
    this.bestScore,
    this.lastScore,
    this.scoreTrend,
    this.lastAttemptAt,
    this.lastPracticeSessionId,
  });

  factory AssignmentStudentProgressModel.fromJson(Map<String, dynamic> json) {
    return AssignmentStudentProgressModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarId: json['avatarId'] as String?,
      hasCompleted: json['hasCompleted'] as bool? ?? false,
      attemptCount: json['attemptCount'] as int? ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble(),
      lastScore: (json['lastScore'] as num?)?.toDouble(),
      scoreTrend: (json['scoreTrend'] as num?)?.toDouble(),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      lastPracticeSessionId: json['lastPracticeSessionId'] as String?,
    );
  }

  final String userId;
  final String displayName;
  final String? avatarId;
  final bool hasCompleted;
  final int attemptCount;
  final double? bestScore;
  final double? lastScore;
  final double? scoreTrend;
  final DateTime? lastAttemptAt;
  final String? lastPracticeSessionId;
}

class AssignmentQuestionDifficultyModel {
  const AssignmentQuestionDifficultyModel({
    required this.questionId,
    required this.questionText,
    required this.displayOrder,
    required this.attemptsCount,
    required this.errorRate,
  });

  factory AssignmentQuestionDifficultyModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AssignmentQuestionDifficultyModel(
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
      errorRate: (json['errorRate'] as num?)?.toDouble() ?? 0,
    );
  }

  final String questionId;
  final String questionText;
  final int displayOrder;
  final int attemptsCount;
  final double errorRate;
}

class ScoreDistributionBucketModel {
  const ScoreDistributionBucketModel({
    required this.minPercent,
    required this.maxPercent,
    required this.studentCount,
  });

  factory ScoreDistributionBucketModel.fromJson(Map<String, dynamic> json) {
    return ScoreDistributionBucketModel(
      minPercent: json['minPercent'] as int? ?? 0,
      maxPercent: json['maxPercent'] as int? ?? 0,
      studentCount: json['studentCount'] as int? ?? 0,
    );
  }

  final int minPercent;
  final int maxPercent;
  final int studentCount;
}
