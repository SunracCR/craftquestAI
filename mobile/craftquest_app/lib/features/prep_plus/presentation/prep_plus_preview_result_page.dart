import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_preview_page.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_score_summary_card.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrepPlusPreviewResultPage extends StatelessWidget {
  const PrepPlusPreviewResultPage({
    super.key,
    required this.result,
    required this.quizTitle,
    required this.catalogItemId,
    this.elapsed,
  });

  final PrepPreviewFinishResultModel result;
  final String quizTitle;
  final String catalogItemId;
  final Duration? elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.prepPlusPreviewResultTitle),
        bottomBar: AppBottomActionBar(
          children: [
            AppGradientPrimaryButton(
              label: l10n.practiceViewResultsAction,
              icon: Icons.fact_check_outlined,
              onPressed: () => _viewReview(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.prepPlusPreviewTryAgainAction,
                    onPressed: () => _tryAgain(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.prepPlusPreviewBackAction,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppPageHeader(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Text(
                  quizTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  AppNoticeBanner(
                    message: l10n.prepPlusPreviewResultDemoNotice,
                    variant: AppNoticeVariant.info,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PracticeScoreSummaryCard(
                    percentage: result.percentage,
                    scoreObtained: result.scoreObtained,
                    scorePossible: result.scorePossible,
                    elapsed: elapsed,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StatsStrip(
                    correct: result.correctAnswers,
                    incorrect: result.incorrectAnswers,
                    omitted: result.omittedAnswers,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionReviewPage(
          sessionId: result.review.practiceSessionId,
          quizTitle: quizTitle,
          initialReview: result.review,
        ),
      ),
    );
  }

  void _tryAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PrepPlusPreviewPage(
          catalogItemId: catalogItemId,
          title: quizTitle,
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.correct,
    required this.incorrect,
    required this.omitted,
    required this.l10n,
  });

  final int correct;
  final int incorrect;
  final int omitted;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_rounded,
            label: l10n.guestResultStatCorrect,
            value: '$correct',
            color: AppColors.accentMint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.cancel_rounded,
            label: l10n.guestResultStatIncorrect,
            value: '$incorrect',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.remove_circle_outline_rounded,
            label: l10n.prepPlusPreviewResultOmitted,
            value: '$omitted',
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
