class TeacherDashboardModel {
  const TeacherDashboardModel({
    required this.totalStudents,
    required this.activeClasses,
    required this.publishedQuizzes,
    required this.sessionsThisWeek,
    required this.uniqueActiveStudentsThisWeek,
    required this.recentActivity,
    required this.insights,
    required this.urgentAssignments,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardModel(
      totalStudents: json['totalStudents'] as int? ?? 0,
      activeClasses: json['activeClasses'] as int? ?? 0,
      publishedQuizzes: json['publishedQuizzes'] as int? ?? 0,
      sessionsThisWeek: json['sessionsThisWeek'] as int? ?? 0,
      uniqueActiveStudentsThisWeek:
          json['uniqueActiveStudentsThisWeek'] as int? ?? 0,
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((e) =>
              ActivityFeedItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>? ?? [])
          .map((e) => TeacherInsightModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      urgentAssignments: (json['urgentAssignments'] as List<dynamic>? ?? [])
          .map((e) =>
              UrgentAssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int totalStudents;
  final int activeClasses;
  final int publishedQuizzes;
  final int sessionsThisWeek;
  final int uniqueActiveStudentsThisWeek;
  final List<ActivityFeedItemModel> recentActivity;
  final List<TeacherInsightModel> insights;
  final List<UrgentAssignmentModel> urgentAssignments;
}

class UrgentAssignmentModel {
  const UrgentAssignmentModel({
    required this.assignmentId,
    required this.classId,
    required this.title,
    required this.className,
    this.dueAt,
    required this.pendingStudents,
    required this.totalMembers,
    required this.uniqueStudentsCompleted,
  });

  factory UrgentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return UrgentAssignmentModel(
      assignmentId: json['assignmentId'] as String,
      classId: json['classId'] as String,
      title: json['title'] as String,
      className: json['className'] as String,
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      pendingStudents: json['pendingStudents'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      uniqueStudentsCompleted:
          json['uniqueStudentsCompleted'] as int? ?? 0,
    );
  }

  final String assignmentId;
  final String classId;
  final String title;
  final String className;
  final DateTime? dueAt;
  final int pendingStudents;
  final int totalMembers;
  final int uniqueStudentsCompleted;
}

class ActivityFeedItemModel {
  const ActivityFeedItemModel({
    required this.practiceSessionId,
    required this.studentName,
    this.studentAvatarId,
    required this.quizTitle,
    this.assignmentTitle,
    required this.scorePercent,
    required this.passed,
    required this.completedAt,
  });

  factory ActivityFeedItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItemModel(
      practiceSessionId: json['practiceSessionId'] as String,
      studentName: json['studentName'] as String,
      studentAvatarId: json['studentAvatarId'] as String?,
      quizTitle: json['quizTitle'] as String,
      assignmentTitle: json['assignmentTitle'] as String?,
      scorePercent: json['scorePercent'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  final String practiceSessionId;
  final String studentName;
  final String? studentAvatarId;
  final String quizTitle;
  final String? assignmentTitle;
  final int scorePercent;
  final bool passed;
  final DateTime completedAt;
}

class TeacherInsightModel {
  const TeacherInsightModel({
    required this.type,
    this.message,
    this.params,
    this.quizId,
    this.assignmentId,
    this.quizTitle,
  });

  factory TeacherInsightModel.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'] as Map<String, dynamic>?;
    return TeacherInsightModel(
      type: json['type'] as String? ?? 'positive',
      message: json['message'] as String?,
      params: rawParams?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      quizId: json['quizId'] as String?,
      assignmentId: json['assignmentId'] as String?,
      quizTitle: json['quizTitle'] as String?,
    );
  }

  final String type;
  final String? message;
  final Map<String, String>? params;
  final String? quizId;
  final String? assignmentId;
  final String? quizTitle;

  bool get isWarning =>
      type == 'warning' || type == 'high_error_rate';
}

class ClassAnalyticsModel {
  const ClassAnalyticsModel({
    required this.classId,
    required this.className,
    required this.totalMembers,
    required this.totalSessions,
    required this.averageScore,
    required this.assignments,
  });

  factory ClassAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return ClassAnalyticsModel(
      classId: json['classId'] as String,
      className: json['className'] as String,
      totalMembers: json['totalMembers'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => AssignmentAnalyticsSummaryModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String classId;
  final String className;
  final int totalMembers;
  final int totalSessions;
  final double averageScore;
  final List<AssignmentAnalyticsSummaryModel> assignments;
}

class AssignmentAnalyticsSummaryModel {
  const AssignmentAnalyticsSummaryModel({
    required this.assignmentId,
    required this.title,
    required this.completedCount,
    required this.totalMembers,
    required this.averageScore,
  });

  factory AssignmentAnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAnalyticsSummaryModel(
      assignmentId: json['assignmentId'] as String,
      title: json['title'] as String,
      completedCount: json['completedCount'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String assignmentId;
  final String title;
  final int completedCount;
  final int totalMembers;
  final double averageScore;

  double get completionRate =>
      totalMembers > 0 ? completedCount / totalMembers : 0.0;
}
