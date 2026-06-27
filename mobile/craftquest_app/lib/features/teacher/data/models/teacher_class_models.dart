import 'package:craftquest_app/core/utils/assignment_dates.dart';

class TeacherClassSummaryModel {
  const TeacherClassSummaryModel({
    required this.classId,
    required this.name,
    this.description,
    required this.status,
    required this.activeMemberCount,
    required this.pendingMemberCount,
    required this.assignmentCount,
  });

  factory TeacherClassSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeacherClassSummaryModel(
      classId: json['classId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      activeMemberCount: json['activeMemberCount'] as int? ?? 0,
      pendingMemberCount: json['pendingMemberCount'] as int? ?? 0,
      assignmentCount: json['assignmentCount'] as int? ?? 0,
    );
  }

  final String classId;
  final String name;
  final String? description;
  final String status;
  final int activeMemberCount;
  final int pendingMemberCount;
  final int assignmentCount;
}

class ClassMemberModel {
  const ClassMemberModel({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.memberRole,
    required this.status,
    required this.joinedAt,
    this.avatarId,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      memberRole: json['memberRole'] as String? ?? 'student',
      status: json['status'] as String? ?? 'active',
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      avatarId: json['avatarId'] as String?,
    );
  }

  final String userId;
  final String displayName;
  final String email;
  final String memberRole;
  final String status;
  final DateTime joinedAt;
  final String? avatarId;

  ClassMemberModel copyWith({
    String? status,
    DateTime? joinedAt,
  }) =>
      ClassMemberModel(
        userId: userId,
        displayName: displayName,
        email: email,
        memberRole: memberRole,
        status: status ?? this.status,
        joinedAt: joinedAt ?? this.joinedAt,
        avatarId: avatarId,
      );
}

class ClassDetailModel {
  const ClassDetailModel({
    required this.classId,
    required this.name,
    this.description,
    required this.status,
    required this.activeMemberCount,
    required this.pendingMemberCount,
    required this.members,
    required this.assignments,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassDetailModel(
      classId: json['classId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      activeMemberCount: json['activeMemberCount'] as int? ?? 0,
      pendingMemberCount: json['pendingMemberCount'] as int? ?? 0,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => ClassMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => AssignmentSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String classId;
  final String name;
  final String? description;
  final String status;
  final int activeMemberCount;
  final int pendingMemberCount;
  final List<ClassMemberModel> members;
  final List<AssignmentSummaryModel> assignments;

  ClassDetailModel copyWith({
    int? activeMemberCount,
    int? pendingMemberCount,
    List<ClassMemberModel>? members,
    List<AssignmentSummaryModel>? assignments,
  }) =>
      ClassDetailModel(
        classId: classId,
        name: name,
        description: description,
        status: status,
        activeMemberCount: activeMemberCount ?? this.activeMemberCount,
        pendingMemberCount: pendingMemberCount ?? this.pendingMemberCount,
        members: members ?? this.members,
        assignments: assignments ?? this.assignments,
      );
}

class AssignmentSummaryModel {
  const AssignmentSummaryModel({
    required this.assignmentId,
    required this.classId,
    required this.quizId,
    required this.title,
    required this.quizTitle,
    required this.status,
    required this.showCorrectAnswersMode,
    this.startsAt,
    this.dueAt,
    this.maxAttempts,
    this.randomizeQuestions = false,
    this.allowStudentRandomizeQuestions = false,
    this.forfeitExitCountsAsAttempt = false,
    required this.completedCount,
    required this.totalMembers,
    required this.createdAt,
  });

  factory AssignmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSummaryModel(
      assignmentId: json['assignmentId'] as String,
      classId: json['classId'] as String,
      quizId: json['quizId'] as String,
      title: json['title'] as String,
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
      randomizeQuestions: json['randomizeQuestions'] as bool? ?? false,
      allowStudentRandomizeQuestions:
          json['allowStudentRandomizeQuestions'] as bool? ?? false,
      forfeitExitCountsAsAttempt:
          json['forfeitExitCountsAsAttempt'] as bool? ?? false,
      completedCount: json['completedCount'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String assignmentId;
  final String classId;
  final String quizId;
  final String title;
  final String quizTitle;
  final String status;
  final String showCorrectAnswersMode;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final int? maxAttempts;
  final bool randomizeQuestions;
  final bool allowStudentRandomizeQuestions;
  final bool forfeitExitCountsAsAttempt;
  final int completedCount;
  final int totalMembers;
  final DateTime createdAt;

  double get completionRate =>
      totalMembers > 0 ? completedCount / totalMembers : 0.0;

  AssignmentSummaryModel copyWith({
    int? totalMembers,
    int? completedCount,
  }) =>
      AssignmentSummaryModel(
        assignmentId: assignmentId,
        classId: classId,
        quizId: quizId,
        title: title,
        quizTitle: quizTitle,
        status: status,
        showCorrectAnswersMode: showCorrectAnswersMode,
        startsAt: startsAt,
        dueAt: dueAt,
        maxAttempts: maxAttempts,
        randomizeQuestions: randomizeQuestions,
        allowStudentRandomizeQuestions: allowStudentRandomizeQuestions,
        forfeitExitCountsAsAttempt: forfeitExitCountsAsAttempt,
        completedCount: completedCount ?? this.completedCount,
        totalMembers: totalMembers ?? this.totalMembers,
        createdAt: createdAt,
      );
}
