class QuizModel {
  const QuizModel({
    required this.quizId,
    required this.title,
    this.description,
    required this.publicationStatus,
    required this.questionCount,
    this.randomizeQuestions = false,
    this.folderId,
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
      randomizeQuestions: json['randomizeQuestions'] as bool? ?? false,
      folderId: json['folderId'] as String?,
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
  final bool randomizeQuestions;
  final String? folderId;
  final String? pendingReviewImportId;
  final int? pendingReviewValidQuestions;
  final bool isOwned;

  bool get hasPendingAiDraft => pendingReviewImportId != null;
}

class QuizFolderModel {
  const QuizFolderModel({
    required this.quizFolderId,
    required this.name,
    this.parentFolderId,
    required this.depth,
    required this.sortOrder,
    required this.quizCount,
  });

  factory QuizFolderModel.fromJson(Map<String, dynamic> json) {
    return QuizFolderModel(
      quizFolderId: json['quizFolderId'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      depth: json['depth'] as int? ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
      quizCount: json['quizCount'] as int? ?? 0,
    );
  }

  final String quizFolderId;
  final String name;
  final String? parentFolderId;
  final int depth;
  final int sortOrder;
  final int quizCount;

  bool get canHaveSubfolders => depth < 2;
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

class QuestionJustificationSourceModel {
  const QuestionJustificationSourceModel({
    this.title,
    this.sourceUrl,
    this.snippet,
    this.pageNumber,
    this.isPrimary = false,
  });

  factory QuestionJustificationSourceModel.fromJson(Map<String, dynamic> json) {
    return QuestionJustificationSourceModel(
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

class QuestionJustificationModel {
  const QuestionJustificationModel({
    this.text,
    this.visibility = 'never',
    this.generatedByAi = false,
    this.sources = const [],
  });

  factory QuestionJustificationModel.fromJson(Map<String, dynamic> json) {
    return QuestionJustificationModel(
      text: json['text'] as String?,
      visibility: json['visibility'] as String? ?? 'never',
      generatedByAi: json['generatedByAi'] as bool? ?? false,
      sources: (json['sources'] as List<dynamic>?)
              ?.map(
                (e) => QuestionJustificationSourceModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  final String? text;
  final String visibility;
  final bool generatedByAi;
  final List<QuestionJustificationSourceModel> sources;
}

class QuestionModel {
  const QuestionModel({
    required this.questionId,
    required this.questionType,
    required this.text,
    this.points = 1,
    required this.answerOptions,
    required this.correctAnswerOptionIds,
    this.explanationVisibility = 'never',
    this.justification,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['questionId'] as String,
      questionType: json['questionType'] as String,
      text: json['text'] as String,
      points: (json['points'] as num?)?.toDouble() ?? 1,
      explanationVisibility:
          json['explanationVisibility'] as String? ?? 'never',
      justification: json['justification'] == null
          ? null
          : QuestionJustificationModel.fromJson(
              json['justification'] as Map<String, dynamic>,
            ),
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
  final String explanationVisibility;
  final QuestionJustificationModel? justification;
  final List<AnswerOptionModel> answerOptions;
  final List<String> correctAnswerOptionIds;
}
