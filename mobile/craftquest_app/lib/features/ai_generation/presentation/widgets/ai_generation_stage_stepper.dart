import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

abstract final class AiGenerationPipelineStages {
  static const ordered = [
    'preparing',
    'outlining',
    'generating',
    'merging',
    'validating',
    'importing',
  ];

  static int indexOf(String? stage) {
    if (stage == null) return -1;
    return ordered.indexOf(stage);
  }
}

class AiGenerationStageStepper extends StatelessWidget {
  const AiGenerationStageStepper({
    super.key,
    required this.l10n,
    required this.currentStage,
    required this.status,
    this.compact = false,
  });

  final AppLocalizations l10n;
  final String? currentStage;
  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _resolveActiveIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < AiGenerationPipelineStages.ordered.length; i++)
          _StageRow(
            label: AiJobStageLabels.stageLabel(
              l10n,
              AiGenerationPipelineStages.ordered[i],
              status,
            ),
            state: i < activeIndex
                ? _StageRowState.done
                : i == activeIndex
                    ? _StageRowState.active
                    : _StageRowState.pending,
            compact: compact,
            isLast: i == AiGenerationPipelineStages.ordered.length - 1,
          ),
      ],
    );
  }

  int _resolveActiveIndex() {
    if (status == 'failed') {
      final idx = AiGenerationPipelineStages.indexOf(currentStage);
      return idx >= 0 ? idx : 0;
    }
    final idx = AiGenerationPipelineStages.indexOf(currentStage);
    if (idx >= 0) return idx;
    if (status == 'pending' || status == 'pending_retry') return 0;
    return 0;
  }
}

enum _StageRowState { done, active, pending }

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.state,
    required this.compact,
    required this.isLast,
  });

  final String label;
  final _StageRowState state;
  final bool compact;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      _StageRowState.done => AppColors.accentMint,
      _StageRowState.active => AppColors.accentCool,
      _StageRowState.pending => AppColors.textSecondary.withValues(alpha: 0.55),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 28 : 32,
            child: Column(
              children: [
                _StageDot(state: state, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: state == _StageRowState.done
                          ? AppColors.accentMint.withValues(alpha: 0.45)
                          : AppColors.inputBorder.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : (compact ? AppSpacing.sm : AppSpacing.md),
                top: 2,
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: state == _StageRowState.pending
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: state == _StageRowState.active
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.state, required this.color});

  final _StageRowState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (state == _StageRowState.done) {
      return Icon(Icons.check_circle_rounded, color: color, size: 22);
    }
    if (state == _StageRowState.active) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    }
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
