int _resolveImportableCount(int? fromApi, int questionCount) {
  if (questionCount == 0) {
    return 0;
  }
  if (fromApi == null || fromApi == 0) {
    return questionCount;
  }
  return fromApi;
}

class ImportStatusModel {
  const ImportStatusModel({
    required this.importId,
    required this.status,
    required this.totalQuestionsDetected,
    required this.validQuestions,
    required this.questionsWithWarnings,
    required this.questionsWithErrors,
  });

  factory ImportStatusModel.fromJson(Map<String, dynamic> json) {
    return ImportStatusModel(
      importId: json['importId'] as String,
      status: json['status'] as String,
      totalQuestionsDetected: json['totalQuestionsDetected'] as int? ?? 0,
      validQuestions: json['validQuestions'] as int? ?? 0,
      questionsWithWarnings: json['questionsWithWarnings'] as int? ?? 0,
      questionsWithErrors: json['questionsWithErrors'] as int? ?? 0,
    );
  }

  final String importId;
  final String status;
  final int totalQuestionsDetected;
  final int validQuestions;
  final int questionsWithWarnings;
  final int questionsWithErrors;
}

class ImportPreviewModel {
  const ImportPreviewModel({
    required this.importId,
    required this.status,
    required this.questions,
    required this.errors,
    this.maxQuestionsPerQuiz,
    this.currentQuestionCountInQuiz = 0,
    required this.importableQuestionCount,
    this.planName,
  });

  factory ImportPreviewModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => PreviewQuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ImportPreviewModel(
      importId: json['importId'] as String,
      status: json['status'] as String,
      questions: questions,
      importableQuestionCount: _resolveImportableCount(
        json['importableQuestionCount'] as int?,
        questions.length,
      ),
      maxQuestionsPerQuiz: json['maxQuestionsPerQuiz'] as int?,
      currentQuestionCountInQuiz:
          json['currentQuestionCountInQuiz'] as int? ?? 0,
      planName: json['planName'] as String?,
      errors: (json['errors'] as List<dynamic>? ?? [])
          .map((e) => ImportErrorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String importId;
  final String status;
  final List<PreviewQuestionModel> questions;
  final List<ImportErrorModel> errors;
  final int? maxQuestionsPerQuiz;
  final int currentQuestionCountInQuiz;
  final int importableQuestionCount;
  final String? planName;

  bool get hasPlanImportCap =>
      maxQuestionsPerQuiz != null &&
      questions.length > importableQuestionCount;

  int get questionsOverPlanCap => questions.length - importableQuestionCount;
}

class PreviewQuestionModel {
  const PreviewQuestionModel({
    required this.type,
    required this.text,
    this.points = 1,
    required this.correctAnswerKeys,
    required this.answerOptions,
  });

  factory PreviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return PreviewQuestionModel(
      type: json['type'] as String,
      text: json['text'] as String,
      points: (json['points'] as num?)?.toDouble() ?? 1,
      correctAnswerKeys: (json['correctAnswerKeys'] as List<dynamic>? ?? [])
          .cast<String>(),
      answerOptions: (json['answerOptions'] as List<dynamic>? ?? [])
          .map((e) => PreviewAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String type;
  final String text;
  final double points;
  final List<String> correctAnswerKeys;
  final List<PreviewAnswerModel> answerOptions;
}

class PreviewAnswerModel {
  const PreviewAnswerModel({required this.key, this.text});

  factory PreviewAnswerModel.fromJson(Map<String, dynamic> json) {
    return PreviewAnswerModel(
      key: json['key'] as String,
      text: json['text'] as String?,
    );
  }

  final String key;
  final String? text;
}

class ImportErrorModel {
  const ImportErrorModel({
    this.rowNumber,
    required this.errorCode,
    required this.message,
    required this.severity,
  });

  factory ImportErrorModel.fromJson(Map<String, dynamic> json) {
    return ImportErrorModel(
      rowNumber: json['rowNumber'] as int?,
      errorCode: json['errorCode'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String? ?? 'error',
    );
  }

  final int? rowNumber;
  final String errorCode;
  final String message;
  final String severity;
}

class ImportConfirmResultModel {
  const ImportConfirmResultModel({
    required this.importId,
    required this.createdQuestions,
    required this.skippedQuestions,
    this.skippedDueToPlanLimit = 0,
    this.maxQuestionsPerQuiz,
    this.planName,
  });

  factory ImportConfirmResultModel.fromJson(Map<String, dynamic> json) {
    return ImportConfirmResultModel(
      importId: json['importId'] as String,
      createdQuestions: json['createdQuestions'] as int? ?? 0,
      skippedQuestions: json['skippedQuestions'] as int? ?? 0,
      skippedDueToPlanLimit: json['skippedDueToPlanLimit'] as int? ?? 0,
      maxQuestionsPerQuiz: json['maxQuestionsPerQuiz'] as int?,
      planName: json['planName'] as String?,
    );
  }

  final String importId;
  final int createdQuestions;
  final int skippedQuestions;
  final int skippedDueToPlanLimit;
  final int? maxQuestionsPerQuiz;
  final String? planName;
}
