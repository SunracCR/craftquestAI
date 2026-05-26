class QuizModel {
  const QuizModel({
    required this.quizId,
    required this.title,
    this.description,
    required this.publicationStatus,
    required this.questionCount,
    this.pendingReviewImportId,
    this.pendingReviewValidQuestions,
    this.isOwned = true,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      publicationStatus: json['publicationStatus'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      pendingReviewImportId: json['pendingReviewImportId'] as String?,
      pendingReviewValidQuestions: json['pendingReviewValidQuestions'] as int?,
      isOwned: json['isOwned'] as bool? ?? true,
    );
  }

  final String quizId;
  final String title;
  final String? description;
  final String publicationStatus;
  final int questionCount;
  final String? pendingReviewImportId;
  final int? pendingReviewValidQuestions;
  final bool isOwned;

  bool get hasPendingAiDraft => pendingReviewImportId != null;
}

class QuestionTypeModel {
  const QuestionTypeModel({
    required this.code,
    required this.name,
    required this.supportsMultipleCorrectAnswers,
    required this.supportsImages,
  });

  factory QuestionTypeModel.fromJson(Map<String, dynamic> json) {
    return QuestionTypeModel(
      code: json['code'] as String,
      name: json['name'] as String,
      supportsMultipleCorrectAnswers:
          json['supportsMultipleCorrectAnswers'] as bool? ?? false,
      supportsImages: json['supportsImages'] as bool? ?? false,
    );
  }

  final String code;
  final String name;
  final bool supportsMultipleCorrectAnswers;
  final bool supportsImages;
}

class AnswerOptionModel {
  const AnswerOptionModel({
    required this.answerOptionId,
    required this.stableKey,
    this.text,
    this.mediaAssetId,
  });

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      answerOptionId: json['answerOptionId'] as String,
      stableKey: json['stableKey'] as String,
      text: json['text'] as String?,
      mediaAssetId: json['mediaAssetId'] as String?,
    );
  }

  final String answerOptionId;
  final String stableKey;
  final String? text;
  final String? mediaAssetId;
}

class QuestionModel {
  const QuestionModel({
    required this.questionId,
    required this.questionType,
    required this.text,
    this.points = 1,
    required this.answerOptions,
    required this.correctAnswerOptionIds,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['questionId'] as String,
      questionType: json['questionType'] as String,
      text: json['text'] as String,
      points: (json['points'] as num?)?.toDouble() ?? 1,
      answerOptions: (json['answerOptions'] as List<dynamic>)
          .map((e) => AnswerOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      correctAnswerOptionIds:
          (json['correctAnswerOptionIds'] as List<dynamic>).cast<String>(),
    );
  }

  final String questionId;
  final String questionType;
  final String text;
  final double points;
  final List<AnswerOptionModel> answerOptions;
  final List<String> correctAnswerOptionIds;
}
