import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Instruction line shown under the question stem during practice sessions.
class PracticeSelectionHint extends StatelessWidget {
  const PracticeSelectionHint({
    super.key,
    required this.isSingleSelect,
  });

  final bool isSingleSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hintText = isSingleSelect
        ? l10n.practiceSelectSingleHint
        : l10n.practiceSelectMultipleHint;

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
}
