class OfflineEntitlementsModel {
  const OfflineEntitlementsModel({
    required this.canDownloadOffline,
    this.maxOfflineQuizzes,
    this.maxOfflineStorageMb,
  });

  factory OfflineEntitlementsModel.fromJson(Map<String, dynamic> json) {
    return OfflineEntitlementsModel(
      canDownloadOffline: json['canDownloadOffline'] as bool? ?? false,
      maxOfflineQuizzes: json['maxOfflineQuizzes'] as int?,
      maxOfflineStorageMb: json['maxOfflineStorageMb'] as int?,
    );
  }

  final bool canDownloadOffline;
  final int? maxOfflineQuizzes;
  final int? maxOfflineStorageMb;
}

class OfflineQuizPackageModel {
  const OfflineQuizPackageModel({
    required this.quizId,
    required this.title,
    this.description,
    required this.contentVersion,
    required this.generatedAt,
    required this.expiresAt,
    required this.packageKeyBase64,
    required this.randomizeQuestions,
    required this.defaultRandomizeAnswerOptions,
    required this.watermarkToken,
    required this.questions,
    required this.mediaAssets,
    required this.entitlements,
  });

  factory OfflineQuizPackageModel.fromJson(Map<String, dynamic> json) {
    return OfflineQuizPackageModel(
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentVersion: json['contentVersion'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      packageKeyBase64: json['packageKeyBase64'] as String,
      randomizeQuestions: json['randomizeQuestions'] as bool? ?? false,
      defaultRandomizeAnswerOptions:
          json['defaultRandomizeAnswerOptions'] as bool? ?? true,
      watermarkToken: json['watermarkToken'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map(
            (e) => OfflinePackageQuestionModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      mediaAssets: (json['mediaAssets'] as List<dynamic>)
          .map(
            (e) => OfflinePackageMediaAssetModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      entitlements: OfflineEntitlementsModel.fromJson(
        json['entitlements'] as Map<String, dynamic>,
      ),
    );
  }

  final String quizId;
  final String title;
  final String? description;
  final String contentVersion;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String packageKeyBase64;
  final bool randomizeQuestions;
  final bool defaultRandomizeAnswerOptions;
  final String watermarkToken;
  final List<OfflinePackageQuestionModel> questions;
  final List<OfflinePackageMediaAssetModel> mediaAssets;
  final OfflineEntitlementsModel entitlements;
}

class OfflinePackageQuestionModel {
  const OfflinePackageQuestionModel({
    required this.questionId,
    required this.sortOrder,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.randomizeAnswerOptions,
    required this.scoringPolicy,
    required this.supportsMultipleCorrectAnswers,
    this.questionMediaAssetId,
    required this.correctAnswerBlob,
    required this.answerOptions,
  });

  factory OfflinePackageQuestionModel.fromJson(Map<String, dynamic> json) {
    return OfflinePackageQuestionModel(
      questionId: json['questionId'] as String,
      sortOrder: json['sortOrder'] as int,
      questionText: json['questionText'] as String,
      questionType: json['questionType'] as String,
      points: (json['points'] as num).toDouble(),
      randomizeAnswerOptions: json['randomizeAnswerOptions'] as bool? ?? true,
      scoringPolicy: json['scoringPolicy'] as String? ?? 'strict',
      supportsMultipleCorrectAnswers:
          json['supportsMultipleCorrectAnswers'] as bool? ?? false,
      questionMediaAssetId: json['questionMediaAssetId'] as String?,
      correctAnswerBlob: json['correctAnswerBlob'] as String,
      answerOptions: (json['answerOptions'] as List<dynamic>)
          .map(
            (e) => OfflinePackageAnswerOptionModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String questionId;
  final int sortOrder;
  final String questionText;
  final String questionType;
  final double points;
  final bool randomizeAnswerOptions;
  final String scoringPolicy;
  final bool supportsMultipleCorrectAnswers;
  final String? questionMediaAssetId;
  final String correctAnswerBlob;
  final List<OfflinePackageAnswerOptionModel> answerOptions;
}

class OfflinePackageAnswerOptionModel {
  const OfflinePackageAnswerOptionModel({
    required this.answerOptionId,
    required this.stableKey,
    required this.defaultSortOrder,
    this.answerText,
    this.mediaAssetId,
  });

  factory OfflinePackageAnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return OfflinePackageAnswerOptionModel(
      answerOptionId: json['answerOptionId'] as String,
      stableKey: json['stableKey'] as String,
      defaultSortOrder: json['defaultSortOrder'] as int,
      answerText: json['answerText'] as String?,
      mediaAssetId: json['mediaAssetId'] as String?,
    );
  }

  final String answerOptionId;
  final String stableKey;
  final int defaultSortOrder;
  final String? answerText;
  final String? mediaAssetId;
}

class OfflinePackageMediaAssetModel {
  const OfflinePackageMediaAssetModel({
    required this.mediaAssetId,
    required this.downloadUrl,
    this.contentType,
    this.fileSizeBytes,
  });

  factory OfflinePackageMediaAssetModel.fromJson(Map<String, dynamic> json) {
    return OfflinePackageMediaAssetModel(
      mediaAssetId: json['mediaAssetId'] as String,
      downloadUrl: json['downloadUrl'] as String,
      contentType: json['contentType'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }

  final String mediaAssetId;
  final String downloadUrl;
  final String? contentType;
  final int? fileSizeBytes;
}

class OfflineSyncAnswerModel {
  const OfflineSyncAnswerModel({
    required this.questionId,
    required this.selectedAnswerOptionIds,
    this.timeSpentSeconds,
    this.answeredAt,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedAnswerOptionIds': selectedAnswerOptionIds,
        if (timeSpentSeconds != null) 'timeSpentSeconds': timeSpentSeconds,
        if (answeredAt != null) 'answeredAt': answeredAt!.toIso8601String(),
      };

  factory OfflineSyncAnswerModel.fromJson(Map<String, dynamic> json) {
    return OfflineSyncAnswerModel(
      questionId: json['questionId'] as String,
      selectedAnswerOptionIds: (json['selectedAnswerOptionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timeSpentSeconds: json['timeSpentSeconds'] as int?,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
    );
  }

  final String questionId;
  final List<String> selectedAnswerOptionIds;
  final int? timeSpentSeconds;
  final DateTime? answeredAt;
}

class OfflineSyncResultModel {
  const OfflineSyncResultModel({
    required this.sessionResult,
    required this.voidedQuestionCount,
    required this.scoreAdjusted,
  });

  factory OfflineSyncResultModel.fromJson(Map<String, dynamic> json) {
    return OfflineSyncResultModel(
      sessionResult: OfflineSyncedSessionResultModel.fromJson(
        json['sessionResult'] as Map<String, dynamic>,
      ),
      voidedQuestionCount: json['voidedQuestionCount'] as int? ?? 0,
      scoreAdjusted: json['scoreAdjusted'] as bool? ?? false,
    );
  }

  final OfflineSyncedSessionResultModel sessionResult;
  final int voidedQuestionCount;
  final bool scoreAdjusted;
}

class OfflineSyncedSessionResultModel {
  const OfflineSyncedSessionResultModel({
    required this.practiceSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.omittedAnswers,
  });

  factory OfflineSyncedSessionResultModel.fromJson(Map<String, dynamic> json) {
    return OfflineSyncedSessionResultModel(
      practiceSessionId: json['practiceSessionId'] as String,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      incorrectAnswers: json['incorrectAnswers'] as int? ?? 0,
      omittedAnswers: json['omittedAnswers'] as int? ?? 0,
    );
  }

  final String practiceSessionId;
  final double scoreObtained;
  final double scorePossible;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int omittedAnswers;
}

class OfflineDownloadedQuizSummaryModel {
  const OfflineDownloadedQuizSummaryModel({
    required this.quizId,
    required this.title,
    required this.contentVersion,
    required this.expiresAt,
    required this.downloadedAt,
    required this.questionCount,
    required this.totalBytes,
    required this.mediaReady,
    required this.mediaTotal,
  });

  final String quizId;
  final String title;
  final String contentVersion;
  final DateTime expiresAt;
  final DateTime downloadedAt;
  final int questionCount;
  final int totalBytes;
  final int mediaReady;
  final int mediaTotal;
}

class OfflineLocalFinishResultModel {
  const OfflineLocalFinishResultModel({
    required this.clientSessionId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.omittedAnswers,
  });

  final String clientSessionId;
  final double scoreObtained;
  final double scorePossible;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int omittedAnswers;
}

class OfflineQuestionFeedbackModel {
  const OfflineQuestionFeedbackModel({
    required this.isCorrect,
    required this.pointsAwarded,
    required this.pointsPossible,
  });

  final bool isCorrect;
  final double pointsAwarded;
  final double pointsPossible;
}

class DownloadProgressModel {
  const DownloadProgressModel({
    required this.quizId,
    required this.phase,
    required this.completedUnits,
    required this.totalUnits,
    this.currentLabel,
    this.isCancelled = false,
  });

  final String quizId;
  final String phase;
  final int completedUnits;
  final int totalUnits;
  final String? currentLabel;
  final bool isCancelled;

  double get fraction =>
      totalUnits <= 0 ? 0 : (completedUnits / totalUnits).clamp(0.0, 1.0);
}
