import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Selector de cantidad de preguntas con slider (techo fijo desde el padre).
class QuestionCountSelector extends StatefulWidget {
  const QuestionCountSelector({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  State<QuestionCountSelector> createState() => _QuestionCountSelectorState();
}

class _QuestionCountSelectorState extends State<QuestionCountSelector> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(QuestionCountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _sliderValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSlide = widget.max > widget.min;
    final displayValue = _sliderValue.round().clamp(widget.min, widget.max);
    final divisions = canSlide ? widget.max - widget.min : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 20,
              color: AppColors.accent.withValues(alpha: 0.9),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.aiGenerationQuestionCount,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            gradient: const LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.accentGold,
                AppColors.accentCool,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppColors.radiusMd - 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.accentWarm, AppColors.accentGold],
                    ).createShader(bounds),
                    child: Text(
                      '$displayValue',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.aiGenerationQuestionCountOfMax(displayValue, widget.max),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.accent.withValues(alpha: 0.22),
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.14),
                      trackHeight: 5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                    ),
                    child: Slider(
                      value: _sliderValue.clamp(
                        widget.min.toDouble(),
                        widget.max.toDouble(),
                      ),
                      min: widget.min.toDouble(),
                      max: widget.max.toDouble(),
                      divisions: divisions,
                      label: '$displayValue',
                      onChanged: canSlide
                          ? (value) {
                              setState(() => _sliderValue = value);
                              widget.onChanged(value.round());
                            }
                          : null,
                      onChangeEnd: canSlide
                          ? (value) => widget.onChangeEnd(value.round())
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
