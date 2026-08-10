import 'package:craftquest_app/l10n/app_localizations.dart';

const String kQuestionImageOptionKey = 'QUESTION_IMAGE';

/// Whether the student may select only one answer option during practice.
bool isSingleSelectQuestionType(String questionType) =>
    questionType == 'single_choice' ||
    questionType == 'true_false' ||
    questionType == 'image_choice' ||
    questionType == 'image_based_question';

extension QuestionTypeLabelExtension on String {
  bool get isQuestionStemOption =>
      toUpperCase() == kQuestionImageOptionKey.toUpperCase();

  String displayLabel(AppLocalizations l10n) => switch (this) {
        'single_choice' => l10n.questionTypeLabelSingleChoice,
        'multiple_choice' => l10n.questionTypeLabelMultipleChoice,
        'true_false' => l10n.questionTypeLabelTrueFalse,
        'image_choice' => l10n.questionTypeLabelImageChoice,
        'image_based_question' => l10n.questionTypeLabelImageBased,
        _ => this,
      };
}
