class QuizAnalyticsModel {
  const QuizAnalyticsModel({
    required this.quizId,
    required this.totalPracticeSessions,
    required this.questions,
  });

  factory QuizAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return QuizAnalyticsModel(
      quizId: json['quizId'] as String,
      totalPracticeSessions: json['totalPracticeSessions'] as int? ?? 0,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String quizId;
  final int totalPracticeSessions;
  final List<QuestionAnalyticsModel> questions;
}

class QuestionAnalyticsModel {
  const QuestionAnalyticsModel({
    required this.questionId,
    required this.questionText,
    required this.attemptsCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.omittedCount,
    required this.answerOptions,
  });

  factory QuestionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnalyticsModel(
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      omittedCount: json['omittedCount'] as int? ?? 0,
      answerOptions: (json['answerOptions'] as List<dynamic>)
          .map(
            (e) => AnswerOptionAnalyticsModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String questionId;
  final String questionText;
  final int attemptsCount;
  final int correctCount;
  final int incorrectCount;
  final int omittedCount;
  final List<AnswerOptionAnalyticsModel> answerOptions;
}

class AnswerOptionAnalyticsModel {
  const AnswerOptionAnalyticsModel({
    required this.answerOptionId,
    required this.stableKey,
    this.text,
    required this.isCorrect,
    required this.selectedCount,
    required this.selectionRate,
  });

  factory AnswerOptionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionAnalyticsModel(
      answerOptionId: json['answerOptionId'] as String,
      stableKey: json['stableKey'] as String,
      text: json['text'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      selectedCount: json['selectedCount'] as int? ?? 0,
      selectionRate: (json['selectionRate'] as num?)?.toDouble() ?? 0,
    );
  }

  final String answerOptionId;
  final String stableKey;
  final String? text;
  final bool isCorrect;
  final int selectedCount;
  final double selectionRate;
}
