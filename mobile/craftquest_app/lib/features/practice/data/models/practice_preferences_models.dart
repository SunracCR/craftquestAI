import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';

class QuizPracticePreferenceModel {
  const QuizPracticePreferenceModel({
    required this.quizId,
    required this.randomizeQuestions,
    required this.showElapsedTimer,
  });

  factory QuizPracticePreferenceModel.fromJson(Map<String, dynamic> json) {
    return QuizPracticePreferenceModel(
      quizId: json['quizId'] as String,
      randomizeQuestions: json['randomizeQuestions'] as bool? ?? false,
      showElapsedTimer: json['showElapsedTimer'] as bool? ?? true,
    );
  }

  final String quizId;
  final bool randomizeQuestions;
  final bool showElapsedTimer;

  Map<String, dynamic> toJson() => {
        'randomizeQuestions': randomizeQuestions,
        'showElapsedTimer': showElapsedTimer,
      };

  PracticeLaunchOptions toLaunchOptions() => PracticeLaunchOptions(
        randomizeQuestions: randomizeQuestions,
        showTimer: showElapsedTimer,
      );
}
