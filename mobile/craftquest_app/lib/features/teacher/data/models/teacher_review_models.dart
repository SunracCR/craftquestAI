import 'package:craftquest_app/core/utils/api_date_time.dart';

class TeacherAttemptModel {
  const TeacherAttemptModel({
    required this.practiceSessionId,
    required this.studentUserId,
    this.studentDisplayName,
    this.studentAvatarId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.showElapsedTimer = false,
  });

  factory TeacherAttemptModel.fromJson(Map<String, dynamic> json) {
    return TeacherAttemptModel(
      practiceSessionId: json['practiceSessionId'] as String,
      studentUserId: json['studentUserId'] as String,
      studentDisplayName: json['studentDisplayName'] as String?,
      studentAvatarId: json['studentAvatarId'] as String?,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      status: json['status'] as String,
      startedAt: parseApiUtcDateTime(json['startedAt'] as String),
      finishedAt: tryParseApiUtcDateTime(json['finishedAt'] as String?),
      durationSeconds: json['durationSeconds'] as int?,
      showElapsedTimer: json['showElapsedTimer'] as bool? ?? false,
    );
  }

  final String practiceSessionId;
  final String studentUserId;
  final String? studentDisplayName;
  final String? studentAvatarId;
  final double scoreObtained;
  final double scorePossible;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final bool showElapsedTimer;

  DateTime get sortDate => finishedAt ?? startedAt;
}

class TeacherPracticeReviewModel {
  const TeacherPracticeReviewModel({
    required this.practiceSessionId,
    required this.quizId,
    required this.status,
    required this.scoreObtained,
    required this.scorePossible,
    this.finishedAt,
    required this.student,
    required this.questions,
    this.revealCorrectAnswers = true,
  });

  factory TeacherPracticeReviewModel.fromJson(Map<String, dynamic> json) {
    return TeacherPracticeReviewModel(
      practiceSessionId: json['practiceSessionId'] as String,
      quizId: json['quizId'] as String,
      status: json['status'] as String,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      finishedAt: tryParseApiUtcDateTime(json['finishedAt'] as String?),
      student: TeacherStudentModel.fromJson(
        json['student'] as Map<String, dynamic>,
      ),
      questions: (json['questions'] as List<dynamic>)
          .map(
            (e) => TeacherQuestionReviewModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      revealCorrectAnswers: json['revealCorrectAnswers'] as bool? ?? true,
    );
  }

  final String practiceSessionId;
  final String quizId;
  final String status;
  final double scoreObtained;
  final double scorePossible;
  final DateTime? finishedAt;
  final TeacherStudentModel student;
  final List<TeacherQuestionReviewModel> questions;
  final bool revealCorrectAnswers;
}

class TeacherStudentModel {
  const TeacherStudentModel({required this.userId, this.displayName});

  factory TeacherStudentModel.fromJson(Map<String, dynamic> json) {
    return TeacherStudentModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  final String userId;
  final String? displayName;
}

class TeacherJustificationSourceReviewModel {
  const TeacherJustificationSourceReviewModel({
    this.title,
    this.sourceUrl,
    this.snippet,
    this.pageNumber,
    this.isPrimary = false,
  });

  factory TeacherJustificationSourceReviewModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherJustificationSourceReviewModel(
      title: json['title'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      snippet: json['snippet'] as String?,
      pageNumber: json['pageNumber'] as int?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  final String? title;
  final String? sourceUrl;
  final String? snippet;
  final int? pageNumber;
  final bool isPrimary;
}

class TeacherQuestionReviewModel {
  const TeacherQuestionReviewModel({
    required this.practiceQuestionSnapshotId,
    required this.questionId,
    required this.displayOrder,
    required this.questionText,
    this.isCorrect,
    required this.pointsAwarded,
    required this.pointsPossible,
    required this.answerStatus,
    required this.answersAsDisplayedToStudent,
    this.questionMediaUrl,
    this.justificationText,
    this.justificationSources = const [],
  });

  factory TeacherQuestionReviewModel.fromJson(Map<String, dynamic> json) {
    return TeacherQuestionReviewModel(
      practiceQuestionSnapshotId: json['practiceQuestionSnapshotId'] as String,
      questionId: json['questionId'] as String,
      displayOrder: json['displayOrder'] as int,
      questionText: json['questionText'] as String,
      isCorrect: json['isCorrect'] as bool?,
      pointsAwarded: (json['pointsAwarded'] as num).toDouble(),
      pointsPossible: (json['pointsPossible'] as num).toDouble(),
      answerStatus: json['answerStatus'] as String,
      questionMediaUrl: json['questionMediaUrl'] as String?,
      justificationText: json['justificationText'] as String?,
      justificationSources: (json['justificationSources'] as List<dynamic>?)
              ?.map(
                (e) => TeacherJustificationSourceReviewModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      answersAsDisplayedToStudent:
          (json['answersAsDisplayedToStudent'] as List<dynamic>)
              .map(
                (e) => TeacherAnswerReviewModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  final String practiceQuestionSnapshotId;
  final String questionId;
  final int displayOrder;
  final String questionText;
  final bool? isCorrect;
  final double pointsAwarded;
  final double pointsPossible;
  final String answerStatus;
  final String? questionMediaUrl;
  final String? justificationText;
  final List<TeacherJustificationSourceReviewModel> justificationSources;
  final List<TeacherAnswerReviewModel> answersAsDisplayedToStudent;
}

class TeacherAnswerReviewModel {
  const TeacherAnswerReviewModel({
    required this.answerOptionId,
    this.stableKey,
    required this.displayOrder,
    required this.displayLabel,
    this.text,
    required this.wasSelected,
    required this.isCorrect,
    this.mediaUrl,
  });

  factory TeacherAnswerReviewModel.fromJson(Map<String, dynamic> json) {
    return TeacherAnswerReviewModel(
      answerOptionId: json['answerOptionId'] as String,
      stableKey: json['stableKey'] as String?,
      displayOrder: json['displayOrder'] as int,
      displayLabel: json['displayLabel'] as String,
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      wasSelected: json['wasSelected'] as bool? ?? false,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  final String answerOptionId;
  final String? stableKey;
  final int displayOrder;
  final String displayLabel;
  final String? text;
  final String? mediaUrl;
  final bool wasSelected;
  final bool isCorrect;
}
