import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/question_type_labels.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Instruction line shown under the question stem during practice sessions.
class PracticeSelectionHint extends StatelessWidget {
  const PracticeSelectionHint({
    super.key,
    required this.isSingleSelect,
    this.questionType,
  });

  final bool isSingleSelect;
  final String? questionType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hintText = isSingleSelect
        ? l10n.practiceSelectSingleHint
        : l10n.practiceSelectMultipleHint;

    if (isSingleSelect) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          hintText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final badgeLabel = questionType?.displayLabel(l10n) ??
        l10n.questionTypeLabelMultipleChoice;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.questionTypeAccent('multiple_choice')
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: AppColors.questionTypeAccent('multiple_choice')
                    .withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              badgeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.questionTypeAccent('multiple_choice'),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hintText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
