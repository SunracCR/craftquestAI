import 'package:craftquest_app/core/utils/ai_generation_allowance.dart';
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
          l10n.upgradePlanHighlightAiCredits(
            AiGenerationAllowance.estimateGenerations(plan.monthlyAiCredits),
            AiGenerationAllowance.estimateGenerations(
              currentEntitlements.monthlyAiCredits,
            ),
          ),
          l10n.upgradeProHighlightQuizzesLimit(
            currentEntitlements.maxQuizzes ?? 0,
          ),
          l10n.upgradeProHighlightQuestionsLimit(
            currentEntitlements.maxQuestionsPerQuiz ?? 0,
          ),
          l10n.upgradeProHighlightShared,
          l10n.upgradeProHighlightDirectInvite,
        ],
      'teacher' => [
          l10n.upgradeTeacherHighlightIncludesPro,
          l10n.upgradePlanHighlightAiCredits(
            AiGenerationAllowance.estimateGenerations(plan.monthlyAiCredits),
            AiGenerationAllowance.estimateGenerations(
              currentEntitlements.monthlyAiCredits,
            ),
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
