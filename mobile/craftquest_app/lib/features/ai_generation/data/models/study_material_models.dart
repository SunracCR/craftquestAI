class StudyMaterialSummaryModel {
  StudyMaterialSummaryModel({
    required this.studyMaterialId,
    required this.title,
    required this.fileType,
    required this.processingStatus,
    required this.needsOcr,
    this.pageCount,
    this.wordCount,
    required this.createdAt,
    this.retentionExpiresAt,
    this.activeAiJobId,
    this.activeAiJobStatus,
    this.activeAiJobStage,
    this.activeAiJobProgressPercent,
    this.pendingReviewImportId,
    this.pendingReviewAiJobId,
  });

  factory StudyMaterialSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialSummaryModel(
      studyMaterialId: json['studyMaterialId'] as String,
      title: json['title'] as String,
      fileType: json['fileType'] as String,
      processingStatus: json['processingStatus'] as String,
      needsOcr: json['needsOcr'] as bool? ?? false,
      pageCount: json['pageCount'] as int?,
      wordCount: json['wordCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retentionExpiresAt: json['retentionExpiresAt'] != null
          ? DateTime.parse(json['retentionExpiresAt'] as String)
          : null,
      activeAiJobId: json['activeAiJobId'] as String?,
      activeAiJobStatus: json['activeAiJobStatus'] as String?,
      activeAiJobStage: json['activeAiJobStage'] as String?,
      activeAiJobProgressPercent: json['activeAiJobProgressPercent'] as int?,
      pendingReviewImportId: json['pendingReviewImportId'] as String?,
      pendingReviewAiJobId: json['pendingReviewAiJobId'] as String?,
    );
  }

  final String studyMaterialId;
  final String title;
  final String fileType;
  final String processingStatus;
  final bool needsOcr;
  final int? pageCount;
  final int? wordCount;
  final DateTime createdAt;
  final DateTime? retentionExpiresAt;
  final String? activeAiJobId;
  final String? activeAiJobStatus;
  final String? activeAiJobStage;
  final int? activeAiJobProgressPercent;
  final String? pendingReviewImportId;
  final String? pendingReviewAiJobId;

  bool get isReady => processingStatus == 'completed';

  bool get hasActiveGenerationJob => activeAiJobId != null;

  bool get hasPendingReviewDraft =>
      pendingReviewImportId != null && pendingReviewAiJobId != null;
}

class StudyMaterialUploadResult {
  StudyMaterialUploadResult({
    required this.studyMaterialId,
    required this.processingStatus,
  });

  factory StudyMaterialUploadResult.fromJson(Map<String, dynamic> json) {
    return StudyMaterialUploadResult(
      studyMaterialId: json['studyMaterialId'] as String,
      processingStatus: json['processingStatus'] as String,
    );
  }

  final String studyMaterialId;
  final String processingStatus;
}

class StudyMaterialPageModel {
  StudyMaterialPageModel({
    required this.pageNumber,
    this.previewText,
    required this.wordCount,
    required this.extractionQuality,
  });

  factory StudyMaterialPageModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialPageModel(
      pageNumber: json['pageNumber'] as int,
      previewText: json['previewText'] as String?,
      wordCount: json['wordCount'] as int,
      extractionQuality: json['extractionQuality'] as String,
    );
  }

  final int pageNumber;
  final String? previewText;
  final int wordCount;
  final String extractionQuality;
}

class StudyMaterialSectionModel {
  StudyMaterialSectionModel({
    required this.title,
    required this.pageFrom,
    required this.pageTo,
  });

  factory StudyMaterialSectionModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialSectionModel(
      title: json['title'] as String,
      pageFrom: json['pageFrom'] as int,
      pageTo: json['pageTo'] as int,
    );
  }

  final String title;
  final int pageFrom;
  final int pageTo;
}

class StudyMaterialDetailModel {
  StudyMaterialDetailModel({
    required this.studyMaterialId,
    required this.title,
    required this.fileType,
    required this.processingStatus,
    required this.needsOcr,
    this.errorMessage,
    this.pageCount,
    this.wordCount,
    this.selectionPageFrom,
    this.selectionPageTo,
    this.selectionTopic,
    this.generatedQuizId,
    required this.pages,
    required this.sections,
    required this.estimatedMaxQuestions,
    required this.requiresTextReview,
    this.editedExtractedText,
    this.languageCode,
  });

  factory StudyMaterialDetailModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialDetailModel(
      studyMaterialId: json['studyMaterialId'] as String,
      title: json['title'] as String,
      fileType: json['fileType'] as String,
      processingStatus: json['processingStatus'] as String,
      needsOcr: json['needsOcr'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      pageCount: json['pageCount'] as int?,
      wordCount: json['wordCount'] as int?,
      selectionPageFrom: json['selectionPageFrom'] as int?,
      selectionPageTo: json['selectionPageTo'] as int?,
      selectionTopic: json['selectionTopic'] as String?,
      generatedQuizId: json['generatedQuizId'] as String?,
      pages: (json['pages'] as List<dynamic>)
          .map((e) => StudyMaterialPageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>)
          .map(
            (e) => StudyMaterialSectionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      estimatedMaxQuestions: json['estimatedMaxQuestions'] as int? ?? 0,
      requiresTextReview: json['requiresTextReview'] as bool? ?? false,
      editedExtractedText: json['editedExtractedText'] as String?,
    );
  }

  final String studyMaterialId;
  final String title;
  final String fileType;
  final String processingStatus;
  final bool needsOcr;
  final String? errorMessage;
  final int? pageCount;
  final int? wordCount;
  final int? selectionPageFrom;
  final int? selectionPageTo;
  final String? selectionTopic;
  final String? generatedQuizId;
  final List<StudyMaterialPageModel> pages;
  final List<StudyMaterialSectionModel> sections;
  final int estimatedMaxQuestions;
  final bool requiresTextReview;
  final String? editedExtractedText;
  final String? languageCode;

  bool get isReady => processingStatus == 'completed';

  String buildDraftExtractedText() {
    if (editedExtractedText != null && editedExtractedText!.trim().isNotEmpty) {
      return editedExtractedText!.trim();
    }

    return pages
        .map((p) => p.previewText?.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .join('\n\n');
  }
}

class QuizGenerationParameters {
  QuizGenerationParameters({
    this.targetQuizId,
    this.questionCount = 15,
    this.language = 'es',
    this.difficulty = 'mixed',
    this.allowedQuestionTypes = const [
      'single_choice',
      'multiple_choice',
      'true_false',
    ],
    this.topicFocus,
    this.pedagogicalGoal = 'assessment',
    this.strictSourceOnly = true,
    this.includeExplanations = true,
    this.preset,
    this.pageFrom = 0,
    this.pageTo = 0,
  });

  final String? targetQuizId;
  final int questionCount;
  final String language;
  final String difficulty;
  final List<String> allowedQuestionTypes;
  final String? topicFocus;
  final String pedagogicalGoal;
  final bool strictSourceOnly;
  final bool includeExplanations;
  final String? preset;
  final int pageFrom;
  final int pageTo;

  Map<String, dynamic> toJson() => {
        if (targetQuizId != null) 'targetQuizId': targetQuizId,
        'questionCount': questionCount,
        'language': language,
        'difficulty': difficulty,
        'allowedQuestionTypes': allowedQuestionTypes,
        if (topicFocus != null && topicFocus!.isNotEmpty) 'topicFocus': topicFocus,
        'pedagogicalGoal': pedagogicalGoal,
        'strictSourceOnly': strictSourceOnly,
        'includeExplanations': includeExplanations,
        if (preset != null) 'preset': preset,
        if (pageFrom > 0) 'pageFrom': pageFrom,
        if (pageTo > 0) 'pageTo': pageTo,
      };
}

class QuizGenerationEstimateModel {
  QuizGenerationEstimateModel({
    required this.creditsRequired,
    required this.aiCreditsAvailable,
    required this.estimatedImportableQuestions,
    required this.maxSelectableQuestions,
    required this.wordsInScope,
    required this.generationLanguage,
  });

  factory QuizGenerationEstimateModel.fromJson(Map<String, dynamic> json) {
    final importable = json['estimatedImportableQuestions'] as int;
    return QuizGenerationEstimateModel(
      creditsRequired: json['creditsRequired'] as int,
      aiCreditsAvailable: json['aiCreditsAvailable'] as int,
      estimatedImportableQuestions: importable,
      maxSelectableQuestions:
          json['maxSelectableQuestions'] as int? ?? importable,
      wordsInScope: json['wordsInScope'] as int,
      generationLanguage: json['generationLanguage'] as String? ?? 'en',
    );
  }

  final int creditsRequired;
  final int aiCreditsAvailable;
  final int estimatedImportableQuestions;
  final int maxSelectableQuestions;
  final int wordsInScope;
  final String generationLanguage;
}

class StartQuizGenerationResult {
  StartQuizGenerationResult({
    required this.aiJobId,
    required this.status,
    this.targetQuizId,
    required this.creditsRequired,
    this.resumedExistingJob = false,
  });

  factory StartQuizGenerationResult.fromJson(Map<String, dynamic> json) {
    return StartQuizGenerationResult(
      aiJobId: json['aiJobId'] as String,
      status: json['status'] as String,
      targetQuizId: json['targetQuizId'] as String?,
      creditsRequired: json['creditsRequired'] as int,
      resumedExistingJob: json['resumedExistingJob'] as bool? ?? false,
    );
  }

  final String aiJobId;
  final String status;
  final String? targetQuizId;
  final int creditsRequired;
  final bool resumedExistingJob;
}
