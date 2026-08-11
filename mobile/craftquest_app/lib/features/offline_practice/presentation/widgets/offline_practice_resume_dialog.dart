import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum OfflinePracticeResumeChoice { resume, startNew, cancel }

Future<OfflinePracticeResumeChoice?> showOfflinePracticeResumeDialog(
  BuildContext context, {
  required int answeredCount,
  required int totalQuestions,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<OfflinePracticeResumeChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.practiceResumeTitle),
      content: Text(
        l10n.practiceResumeMessage(answeredCount, totalQuestions),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(OfflinePracticeResumeChoice.cancel),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(ctx).pop(OfflinePracticeResumeChoice.startNew),
          child: Text(l10n.practiceStartNewAction),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(OfflinePracticeResumeChoice.resume),
          child: Text(l10n.practiceContinueAction),
        ),
      ],
    ),
  );
}
