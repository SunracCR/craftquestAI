import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_highlight_stat_row.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PracticeScoreSummaryCard extends StatelessWidget {
  const PracticeScoreSummaryCard({
    super.key,
    required this.percentage,
    required this.scoreObtained,
    required this.scorePossible,
    this.elapsed,
  });

  final double percentage;
  final double scoreObtained;
  final double scorePossible;
  final Duration? elapsed;

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            l10n.practicePercentageLabel(percentage),
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.practiceScoreLabel(scoreObtained, scorePossible),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (elapsed != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppHighlightStatRow(
              icon: Icons.timer_outlined,
              label: l10n.practiceDurationLabel,
              value: formatDuration(elapsed!),
              color: AppColors.accentCool,
            ),
          ],
        ],
      ),
    );
  }
}
