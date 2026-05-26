import 'package:craftquest_app/l10n/app_localizations.dart';

/// Localized labels for user role codes returned by the API.
abstract final class UserRoleLabels {
  static int _sortKey(String code) => switch (code) {
        'teacher' => 0,
        'institution_admin' => 1,
        'content_admin' => 2,
        'super_admin' => 3,
        'student' => 4,
        _ => 5,
      };

  static String labelFor(String roleCode, AppLocalizations l10n) =>
      switch (roleCode) {
        'teacher' => l10n.roleTeacherLabel,
        'student' => l10n.roleStudentLabel,
        'institution_admin' => l10n.roleInstitutionAdminLabel,
        'content_admin' => l10n.roleContentAdminLabel,
        'super_admin' => l10n.roleSuperAdminLabel,
        _ => roleCode,
      };

  /// All roles, localized and ordered (teacher first when present).
  static String formatRoles(Iterable<String> roles, AppLocalizations l10n) {
    if (roles.isEmpty) {
      return l10n.roleUnknown;
    }

    final sorted = roles.toSet().toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    return sorted.map((code) => labelFor(code, l10n)).join(' · ');
  }
}
