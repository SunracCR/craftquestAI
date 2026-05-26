import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_map_sheet.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_styles.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Cabecera compacta: contador, barra segmentada, leyenda y acceso al mapa.
class PracticeQuestionNavHeader extends StatelessWidget {
  const PracticeQuestionNavHeader({
    super.key,
    required this.currentIndex,
    required this.displayOrder,
    required this.totalQuestions,
    required this.completedCount,
    required this.statuses,
    required this.onSelected,
  });

  final int currentIndex;
  final int displayOrder;
  final int totalQuestions;
  final int completedCount;
  final List<PracticeQuestionNavStatus> statuses;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.practiceQuestionCounter(
                      displayOrder,
                      totalQuestions,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.practiceProgressCompletedLabel(
                      completedCount,
                      totalQuestions,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => PracticeQuestionMapSheet.show(
                context,
                currentIndex: currentIndex,
                statuses: statuses,
                onSelected: onSelected,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(l10n.practiceOpenQuestionMapAction),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SegmentedProgressBar(
          currentIndex: currentIndex,
          statuses: statuses,
          onSegmentTap: onSelected,
        ),
        const SizedBox(height: AppSpacing.xs),
        _NavLegend(l10n: l10n),
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.currentIndex,
    required this.statuses,
    required this.onSegmentTap,
  });

  final int currentIndex;
  final List<PracticeQuestionNavStatus> statuses;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final segmentWidth =
            (constraints.maxWidth - gap * (statuses.length - 1)) / statuses.length;

        return SizedBox(
          height: 10,
          child: Row(
            children: List.generate(statuses.length, (index) {
              final status = statuses[index];
              final isCurrent = index == currentIndex;
              final fillColor = PracticeQuestionNavStyles.segmentFill(status);
              final height = isCurrent ? 10.0 : 7.0;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < statuses.length - 1 ? gap : 0,
                ),
                child: Semantics(
                  button: true,
                  label: AppLocalizations.of(context)!
                      .practiceQuestionNavTooltip(index + 1),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSegmentTap(index),
                      borderRadius: BorderRadius.circular(3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: segmentWidth,
                        height: height,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(3),
                          border: isCurrent
                              ? Border.fromBorderSide(
                                  PracticeQuestionNavStyles.currentOutline(
                                        true,
                                      )!,
                                )
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: PracticeQuestionNavStyles
                                        .currentBorder
                                        .withValues(alpha: 0.35),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

}

class _NavLegend extends StatelessWidget {
  const _NavLegend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        _LegendItem(
          color: AppColors.accentMint,
          label: l10n.practiceNavLegendAnswered,
        ),
        _LegendItem(
          color: AppColors.surfaceHighlight,
          label: l10n.practiceNavLegendPending,
        ),
        _LegendItem(
          color: PracticeQuestionNavStyles.currentBorder,
          label: l10n.practiceNavLegendCurrent,
          outlined: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border: outlined
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
