import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';

abstract final class PlanUpgradeHighlights {
  static List<String> forPlan(
    AppLocalizations l10n,
    UpgradeablePlanModel plan, {
    required PlanEntitlementsModel currentEntitlements,
  }) {
    return switch (plan.code.toLowerCase()) {
      'pro' => [
          l10n.upgradeProHighlightQuizzesLimit(
            currentEntitlements.maxQuizzes ?? 0,
          ),
          l10n.upgradeProHighlightQuestionsLimit(
            currentEntitlements.maxQuestionsPerQuiz ?? 0,
          ),
          l10n.upgradePlanHighlightAiCredits(
            plan.monthlyAiCredits,
            currentEntitlements.monthlyAiCredits,
          ),
          l10n.upgradeProHighlightShared,
          l10n.upgradeProHighlightDirectInvite,
        ],
      'teacher' => [
          l10n.upgradeTeacherHighlightIncludesPro,
          l10n.upgradePlanHighlightAiCredits(
            plan.monthlyAiCredits,
            currentEntitlements.monthlyAiCredits,
          ),
          l10n.upgradeTeacherHighlightClasses,
          l10n.upgradeTeacherHighlightAssignments,
          l10n.upgradeTeacherHighlightGroupShare,
          l10n.upgradeTeacherHighlightTracking,
        ],
      'institution' => [l10n.upgradeInstitutionHighlight],
      _ => const [],
    };
  }
}
