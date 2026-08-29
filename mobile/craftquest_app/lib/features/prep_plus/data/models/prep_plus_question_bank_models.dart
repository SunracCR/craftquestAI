class PrepPracticeSectionModel {
  const PrepPracticeSectionModel({
    required this.sectionId,
    required this.name,
    required this.questionCount,
  });

  factory PrepPracticeSectionModel.fromJson(Map<String, dynamic> json) {
    return PrepPracticeSectionModel(
      sectionId: json['sectionId'] as String,
      name: json['name'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }

  final String sectionId;
  final String name;
  final int questionCount;
}

class PrepPracticePoolModel {
  const PrepPracticePoolModel({
    required this.availableQuestionCount,
    required this.maxQuestionCount,
  });

  factory PrepPracticePoolModel.fromJson(Map<String, dynamic> json) {
    return PrepPracticePoolModel(
      availableQuestionCount: json['availableQuestionCount'] as int? ?? 0,
      maxQuestionCount: json['maxQuestionCount'] as int? ?? 0,
    );
  }

  final int availableQuestionCount;
  final int maxQuestionCount;
}

class PrepAdminQuizSectionModel {
  const PrepAdminQuizSectionModel({
    required this.sectionId,
    required this.name,
    required this.sortOrder,
    required this.questionCount,
  });

  factory PrepAdminQuizSectionModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminQuizSectionModel(
      sectionId: json['sectionId'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }

  final String sectionId;
  final String name;
  final int sortOrder;
  final int questionCount;
}

class PrepAdminQuestionBankQuestionModel {
  const PrepAdminQuestionBankQuestionModel({
    required this.questionId,
    required this.sortOrder,
    required this.promptPreview,
    this.sectionId,
    this.difficulty,
  });

  factory PrepAdminQuestionBankQuestionModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminQuestionBankQuestionModel(
      questionId: json['questionId'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      promptPreview: json['promptPreview'] as String? ?? '',
      sectionId: json['sectionId'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  final String questionId;
  final int sortOrder;
  final String promptPreview;
  final String? sectionId;
  final String? difficulty;
}

class PrepAdminQuestionBankModel {
  const PrepAdminQuestionBankModel({
    required this.catalogItemId,
    required this.quizId,
    required this.supportsCustomPractice,
    required this.untaggedQuestionCount,
    this.sections = const [],
    this.questions = const [],
  });

  factory PrepAdminQuestionBankModel.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return PrepAdminQuestionBankModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      supportsCustomPractice: json['supportsCustomPractice'] as bool? ?? false,
      untaggedQuestionCount: json['untaggedQuestionCount'] as int? ?? 0,
      sections: sectionsJson
          .map((e) => PrepAdminQuizSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      questions: questionsJson
          .map((e) =>
              PrepAdminQuestionBankQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String catalogItemId;
  final String quizId;
  final bool supportsCustomPractice;
  final int untaggedQuestionCount;
  final List<PrepAdminQuizSectionModel> sections;
  final List<PrepAdminQuestionBankQuestionModel> questions;
}
