import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/smoothed_progress_controller.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_summary_model.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiActivityTile extends StatefulWidget {
  const AiActivityTile({
    super.key,
    required this.job,
    required this.onTap,
  });

  final AiJobSummaryModel job;
  final VoidCallback onTap;

  @override
  State<AiActivityTile> createState() => _AiActivityTileState();
}

class _AiActivityTileState extends State<AiActivityTile> {
  final _smoothedProgress = SmoothedProgressController();

  @override
  void initState() {
    super.initState();
    _smoothedProgress.addListener(_onProgressTick);
    _syncProgress();
  }

  @override
  void didUpdateWidget(AiActivityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.aiJobId != widget.job.aiJobId) {
      _smoothedProgress.reset();
    }
    _syncProgress();
  }

  @override
  void dispose() {
    _smoothedProgress.removeListener(_onProgressTick);
    _smoothedProgress.disposeController();
    super.dispose();
  }

  void _onProgressTick() {
    if (mounted) setState(() {});
  }

  void _syncProgress() {
    _smoothedProgress.updateFromServer(
      progressPercent: widget.job.progressPercent,
      stage: widget.job.stage,
      isActiveGeneration: widget.job.isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusLabel = AiJobStageLabels.inboxStatusLabel(l10n, job);
    final pageRange = AiJobStageLabels.pageRangeLabel(l10n, job.pageFrom, job.pageTo);
    final statusColor = _statusColor(job);
    final displayPercent = _smoothedProgress.displayPercent;
    final showProgress = job.isActive &&
        (job.progressPercent != null || displayPercent > 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
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
                if (showProgress) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: AppColors.surface),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (displayPercent / 100).clamp(0.02, 1),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, AppColors.accentMint],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.aiGenerationProgressPercent(displayPercent),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
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
