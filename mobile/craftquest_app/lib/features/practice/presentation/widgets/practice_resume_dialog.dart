import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum PracticeResumeChoice { resume, startNew, cancel }

Future<PracticeResumeChoice?> showPracticeResumeDialog(
  BuildContext context, {
  required PracticeActiveSessionModel summary,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<PracticeResumeChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.practiceResumeTitle),
      content: Text(
        l10n.practiceResumeMessage(summary.answeredCount, summary.totalQuestions),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(PracticeResumeChoice.cancel),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(PracticeResumeChoice.startNew),
          child: Text(l10n.practiceStartNewAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(PracticeResumeChoice.resume),
          child: Text(l10n.practiceContinueAction),
        ),
      ],
    ),
  );
}
