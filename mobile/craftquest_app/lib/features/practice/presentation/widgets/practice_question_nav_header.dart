import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_map_sheet.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_styles.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Cabecera mínima: contador, cronómetro opcional, barra segmentada y mapa.
class PracticeQuestionNavHeader extends StatelessWidget {
  const PracticeQuestionNavHeader({
    super.key,
    required this.currentIndex,
    required this.displayOrder,
    required this.totalQuestions,
    required this.statuses,
    required this.onSelected,
    this.elapsedTime,
  });

  final int currentIndex;
  final int displayOrder;
  final int totalQuestions;
  final List<PracticeQuestionNavStatus> statuses;
  final ValueChanged<int> onSelected;

  /// Solo dígitos (p. ej. `05:23`), sin prefijo «Tiempo».
  final String? elapsedTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$displayOrder / $totalQuestions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (elapsedTime != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 4),
              Text(
                elapsedTime!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              tooltip: l10n.practiceOpenQuestionMapAction,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => PracticeQuestionMapSheet.show(
                context,
                currentIndex: currentIndex,
                statuses: statuses,
                onSelected: onSelected,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 20),
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _SegmentedProgressBar(
          currentIndex: currentIndex,
          statuses: statuses,
          onSegmentTap: onSelected,
        ),
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
        const gap = 2.0;
        final segmentWidth =
            (constraints.maxWidth - gap * (statuses.length - 1)) / statuses.length;

        return SizedBox(
          height: 8,
          child: Row(
            children: List.generate(statuses.length, (index) {
              final status = statuses[index];
              final isCurrent = index == currentIndex;
              final fillColor = PracticeQuestionNavStyles.segmentFill(status);

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
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: segmentWidth,
                        height: isCurrent ? 8.0 : 6.0,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(2),
                          border: isCurrent
                              ? Border.fromBorderSide(
                                  PracticeQuestionNavStyles.currentOutline(
                                        true,
                                      )!,
                                )
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
