import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/question_type_labels.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pregunta en acordeón (autor): borde lateral por tipo, resto neutro.
class AppQuestionAccordionTile extends StatelessWidget {
  const AppQuestionAccordionTile({
    super.key,
    required this.index,
    required this.question,
    required this.l10n,
    required this.expanded,
    required this.onExpansionChanged,
    this.onEdit,
    this.onDelete,
  });

  final int index;
  final QuestionModel question;
  final AppLocalizations l10n;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  List<AnswerOptionModel> get _visibleOptions => question.answerOptions
      .where((o) => !o.stableKey.isQuestionStemOption)
      .toList();

  Set<String> get _correctIds => question.correctAnswerOptionIds.toSet();

  Color get _typeAccent => AppColors.questionTypeAccent(question.questionType);

  String _formatPoints(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String get _correctKeysLabel {
    final keys = _visibleOptions
        .where((o) => _correctIds.contains(o.answerOptionId))
        .map((o) => o.stableKey)
        .toList();
    if (keys.isEmpty) return '';
    final joined = keys.join(', ');
    return keys.length == 1
        ? l10n.quizDetailCorrectKeys(joined)
        : l10n.quizDetailCorrectKeysPlural(joined);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dividerColor = AppColors.textSecondary.withValues(alpha: 0.12);

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _typeAccent.withValues(alpha: 0.85),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: expanded
                  ? AppColors.surfaceHighlight.withValues(alpha: 0.35)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onExpansionChanged(!expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.questionListIndexLabel(index)} · ${question.questionType.displayLabel(l10n)} · ${l10n.questionPointsValue(_formatPoints(question.points))}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              question.text,
                              maxLines: expanded ? null : 2,
                              overflow: expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!expanded) ...[
                              const SizedBox(height: 4),
                              Text(
                                l10n.quizDetailOptionCount(
                                  _visibleOptions.length,
                                ),
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.textSecondary,
                          tooltip: l10n.editQuestionAction,
                          onPressed: onEdit,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          color: AppColors.textSecondary,
                          tooltip: l10n.deleteQuestionAction,
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 1, color: dividerColor),
                          const SizedBox(height: AppSpacing.sm),
                          ..._visibleOptions.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: _OptionRow(
                                option: option,
                                isCorrect: _correctIds
                                    .contains(option.answerOptionId),
                              ),
                            ),
                          ),
                          if (_correctKeysLabel.isNotEmpty)
                            Text(
                              _correctKeysLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isCorrect,
  });

  final AnswerOptionModel option;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final text = option.text?.trim();
    final displayText = (text == null || text.isEmpty) ? '—' : text;
    final keyWidth = option.stableKey.length <= 2 ? 28.0 : 44.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: keyWidth,
          child: Text(
            option.stableKey,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isCorrect
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            displayText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                ),
          ),
        ),
        if (isCorrect)
          Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.accent.withValues(alpha: 0.85),
          ),
      ],
    );
  }
}
