import 'package:craftquest_app/l10n/app_localizations.dart';

abstract final class PlanUpgradeHighlights {
  static List<String> forPlanCode(AppLocalizations l10n, String planCode) {
    return switch (planCode.toLowerCase()) {
      'pro' => [
          l10n.upgradeProHighlightQuizzes,
          l10n.upgradeProHighlightQuestions,
          l10n.upgradeProHighlightAiCredits,
          l10n.upgradeProHighlightShared,
          l10n.upgradeProHighlightDirectInvite,
        ],
      'teacher' => [
          l10n.upgradeTeacherHighlightIncludesPro,
          l10n.upgradeTeacherHighlightAiCredits,
          l10n.upgradeTeacherHighlightClasses,
          l10n.upgradeTeacherHighlightAssignments,
          l10n.upgradeTeacherHighlightGroupShare,
          l10n.upgradeTeacherHighlightTracking,
        ],
      _ => const [],
    };
  }
}
