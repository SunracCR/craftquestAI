import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Opciones de práctica colapsables para detalle Prep+.
class PrepPlusPracticeOptionsPanel extends StatefulWidget {
  const PrepPlusPracticeOptionsPanel({
    super.key,
    required this.randomizeQuestions,
    required this.showTimer,
    required this.enableSoundEffects,
    required this.onRandomizeQuestionsChanged,
    required this.onShowTimerChanged,
    required this.onSoundEffectsChanged,
    this.isLoading = false,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableSoundEffects;
  final ValueChanged<bool> onRandomizeQuestionsChanged;
  final ValueChanged<bool> onShowTimerChanged;
  final ValueChanged<bool> onSoundEffectsChanged;
  final bool isLoading;

  @override
  State<PrepPlusPracticeOptionsPanel> createState() =>
      _PrepPlusPracticeOptionsPanelState();
}

class _PrepPlusPracticeOptionsPanelState
    extends State<PrepPlusPracticeOptionsPanel> {
  bool _expanded = false;

  String _summary(AppLocalizations l10n) {
    final parts = <String>[];
    if (widget.randomizeQuestions) {
      parts.add(l10n.prepPlusPracticeOptionRandom);
    }
    if (widget.showTimer) {
      parts.add(l10n.prepPlusPracticeOptionTimer);
    }
    if (widget.enableSoundEffects) {
      parts.add(l10n.prepPlusPracticeOptionSound);
    }
    if (parts.isEmpty) {
      return l10n.prepPlusPracticeOptionsSummaryDefault;
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.prepPlusPracticeOptionsTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summary(l10n),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.12),
            ),
            PracticeLaunchOptionsCard(
              randomizeQuestions: widget.randomizeQuestions,
              showTimer: widget.showTimer,
              enableSoundEffects: widget.enableSoundEffects,
              onRandomizeQuestionsChanged: widget.onRandomizeQuestionsChanged,
              onShowTimerChanged: widget.onShowTimerChanged,
              onSoundEffectsChanged: widget.onSoundEffectsChanged,
              showSectionTitle: false,
            ),
          ],
        ],
      ),
    );
  }
}
