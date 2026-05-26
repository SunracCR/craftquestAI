import 'package:craftquest_app/l10n/app_localizations.dart';

/// Holds the current [AppLocalizations] from [MaterialApp] for code without [BuildContext].
abstract final class LocalizedMessageHolder {
  static AppLocalizations? current;

  static void update(AppLocalizations? localizations) {
    current = localizations;
  }
}
