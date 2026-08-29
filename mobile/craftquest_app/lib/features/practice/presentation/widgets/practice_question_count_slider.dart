import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Slider 1…poolCount for choosing how many questions to practice.
class PracticeQuestionCountSlider extends StatelessWidget {
  const PracticeQuestionCountSlider({
    super.key,
    required this.poolCount,
    required this.selectedCount,
    required this.onChanged,
    this.showTitle = true,
  });

  final int poolCount;
  final int selectedCount;
  final ValueChanged<int> onChanged;
  final bool showTitle;

  static int defaultCountForPool(int pool) {
    if (pool <= 0) return 1;
    return pool < 15 ? pool : 15;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectivePool = poolCount > 0 ? poolCount : 1;
    final value = selectedCount.clamp(1, effectivePool).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            l10n.prepPlusCustomPracticeCountTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          l10n.prepPlusCustomPracticeSliderLabel(
            selectedCount.clamp(1, effectivePool),
            effectivePool,
          ),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Slider(
          value: value,
          min: 1,
          max: effectivePool.toDouble(),
          divisions: effectivePool > 1 ? effectivePool - 1 : null,
          label: '${selectedCount.clamp(1, effectivePool)}',
          onChanged: poolCount >= 1
              ? (v) => onChanged(v.round())
              : null,
        ),
      ],
    );
  }
}
