class AiJobSummaryModel {
  AiJobSummaryModel({
    required this.aiJobId,
    required this.status,
    required this.jobType,
    this.stage,
    this.progressPercent,
    this.errorCode,
    this.studyMaterialId,
    this.studyMaterialTitle,
    this.targetQuizId,
    this.questionImportBatchId,
    this.importReadyForReview = false,
    this.pageFrom,
    this.pageTo,
    this.questionCount,
    required this.createdAt,
    this.completedAt,
  });

  factory AiJobSummaryModel.fromJson(Map<String, dynamic> json) {
    return AiJobSummaryModel(
      aiJobId: json['aiJobId'] as String,
      status: json['status'] as String,
      jobType: json['jobType'] as String,
      stage: json['stage'] as String?,
      progressPercent: json['progressPercent'] as int?,
      errorCode: json['errorCode'] as String?,
      studyMaterialId: json['studyMaterialId'] as String?,
      studyMaterialTitle: json['studyMaterialTitle'] as String?,
      targetQuizId: json['targetQuizId'] as String?,
      questionImportBatchId: json['questionImportBatchId'] as String?,
      importReadyForReview: json['importReadyForReview'] as bool? ?? false,
      pageFrom: json['pageFrom'] as int?,
      pageTo: json['pageTo'] as int?,
      questionCount: json['questionCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  final String aiJobId;
  final String status;
  final String jobType;
  final String? stage;
  final int? progressPercent;
  final String? errorCode;
  final String? studyMaterialId;
  final String? studyMaterialTitle;
  final String? targetQuizId;
  final String? questionImportBatchId;
  final bool importReadyForReview;
  final int? pageFrom;
  final int? pageTo;
  final int? questionCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isActive =>
      status == 'pending' || status == 'processing' || status == 'pending_retry';

  bool get isFailed => status == 'failed';

  bool get isCompleted => status == 'completed';

  bool get canOpenPreview =>
      isCompleted && importReadyForReview && questionImportBatchId != null;
}
