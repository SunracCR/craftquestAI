import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_summary_model.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiActivityTile extends StatelessWidget {
  const AiActivityTile({
    super.key,
    required this.job,
    required this.onTap,
  });

  final AiJobSummaryModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusLabel = AiJobStageLabels.inboxStatusLabel(l10n, job);
    final pageRange = AiJobStageLabels.pageRangeLabel(l10n, job.pageFrom, job.pageTo);
    final statusColor = _statusColor(job);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceHighlight,
                AppColors.surface.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_statusIcon(job), color: statusColor, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.studyMaterialTitle ?? l10n.aiActivityUnknownMaterial,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pageRange != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              pageRange,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
                if (job.isActive && job.progressPercent != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: job.progressPercent! / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surface,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.aiGenerationProgressPercent(job.progressPercent!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _actionHint(l10n, job),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.accentCool,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _actionHint(AppLocalizations l10n, AiJobSummaryModel job) {
    if (job.canOpenPreview) {
      return l10n.aiActivityReviewDraft;
    }
    if (job.isActive) {
      return l10n.aiActivityViewProgress;
    }
    if (job.isFailed) {
      return l10n.aiActivityTapForDetails;
    }
    return l10n.aiActivityViewProgress;
  }

  static Color _statusColor(AiJobSummaryModel job) {
    if (job.isFailed) {
      return AppColors.error;
    }
    if (job.canOpenPreview) {
      return AppColors.accentMint;
    }
    if (job.isActive) {
      return AppColors.accentCool;
    }
    return AppColors.textSecondary;
  }

  static IconData _statusIcon(AiJobSummaryModel job) {
    if (job.canOpenPreview) {
      return Icons.fact_check_outlined;
    }
    if (job.isFailed) {
      return Icons.error_outline_rounded;
    }
    if (job.isActive) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
