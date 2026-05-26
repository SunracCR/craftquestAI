class GuestVisitModel {
  const GuestVisitModel({
    required this.guestVisitId,
    required this.token,
    required this.quizId,
    required this.quizTitle,
    this.quizDescription,
    required this.questionCount,
    required this.expiresAt,
  });

  factory GuestVisitModel.fromJson(Map<String, dynamic> json) {
    return GuestVisitModel(
      guestVisitId: json['guestVisitId'] as String,
      token: json['token'] as String,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      quizDescription: json['quizDescription'] as String?,
      questionCount: json['questionCount'] as int? ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String guestVisitId;
  final String token;
  final String quizId;
  final String quizTitle;
  final String? quizDescription;
  final int questionCount;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class GuestAttemptModel {
  const GuestAttemptModel({
    required this.practiceSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.showElapsedTimer = false,
  });

  factory GuestAttemptModel.fromJson(Map<String, dynamic> json) {
    return GuestAttemptModel(
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

  double get percentage =>
      scorePossible > 0 ? (scoreObtained / scorePossible * 100) : 0;
}
