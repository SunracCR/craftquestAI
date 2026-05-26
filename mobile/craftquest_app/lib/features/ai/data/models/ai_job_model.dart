class AiJobModel {
  AiJobModel({
    required this.aiJobId,
    required this.status,
    required this.jobType,
    this.errorMessage,
    this.errorCode,
    this.nextRetryAt,
    this.retryAttempt = 0,
    this.creditsConsumed,
    this.questionImportBatchId,
    this.targetQuizId,
    this.studyMaterialId,
    this.studyMaterialTitle,
    this.stage,
    this.progressPercent,
    this.pageFrom,
    this.pageTo,
    this.questionCount,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory AiJobModel.fromJson(Map<String, dynamic> json) {
    return AiJobModel(
      aiJobId: json['aiJobId'] as String,
      status: json['status'] as String,
      jobType: json['jobType'] as String,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'] as String)
          : null,
      retryAttempt: json['retryAttempt'] as int? ?? 0,
      creditsConsumed: json['creditsConsumed'] as int?,
      questionImportBatchId: json['questionImportBatchId'] as String?,
      targetQuizId: json['targetQuizId'] as String?,
      studyMaterialId: json['studyMaterialId'] as String?,
      studyMaterialTitle: json['studyMaterialTitle'] as String?,
      stage: json['stage'] as String?,
      progressPercent: json['progressPercent'] as int?,
      pageFrom: json['pageFrom'] as int?,
      pageTo: json['pageTo'] as int?,
      questionCount: json['questionCount'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  final String aiJobId;
  final String status;
  final String jobType;
  final String? errorMessage;
  final String? errorCode;
  final DateTime? nextRetryAt;
  final int retryAttempt;
  final int? creditsConsumed;
  final String? questionImportBatchId;
  final String? targetQuizId;
  final String? studyMaterialId;
  final String? studyMaterialTitle;
  final String? stage;
  final int? progressPercent;
  final int? pageFrom;
  final int? pageTo;
  final int? questionCount;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isDeferredRetry => status == 'pending_retry';
  bool get isPending =>
      status == 'pending' || status == 'processing' || isDeferredRetry;

  bool get creditsWereNotConsumed =>
      isFailed && (creditsConsumed == null || creditsConsumed == 0);

  bool get isActiveGeneration =>
      status == 'pending' || status == 'processing' || isDeferredRetry;

  Duration? get age =>
      createdAt == null ? null : DateTime.now().toUtc().difference(createdAt!.toUtc());
}
