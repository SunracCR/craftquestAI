import 'package:craftquest_app/l10n/app_localizations.dart';

extension PublicationStatusLabelExtension on String {
  String publicationStatusLabel(AppLocalizations l10n) => switch (this) {
        'published' => l10n.quizStatusPublished,
        'draft' => l10n.quizStatusDraft,
        _ => this,
      };
}
