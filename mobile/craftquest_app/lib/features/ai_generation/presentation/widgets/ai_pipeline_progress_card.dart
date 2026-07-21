import 'dart:math' as math;

import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/ai_generation_stage_stepper.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiPipelineProgressCard extends StatelessWidget {
  const AiPipelineProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percent,
    this.showStepper = false,
    this.stage,
    this.status = 'processing',
    this.l10n,
    this.footer,
    this.showStalledPulse = false,
    this.indeterminate = false,
  });

  final String title;
  final String subtitle;
  final int percent;
  final bool showStepper;
  final String? stage;
  final String status;
  final AppLocalizations? l10n;
  final Widget? footer;
  final bool showStalledPulse;
  final bool indeterminate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = percent.clamp(0, 100);
    final fraction = indeterminate ? null : clamped / 100.0;

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: _ProgressRing(
              percent: clamped,
              indeterminate: indeterminate,
              pulse: showStalledPulse,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _GradientProgressBar(
            value: fraction,
            indeterminate: indeterminate,
            pulse: showStalledPulse,
          ),
          if (l10n != null && !indeterminate) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n!.aiGenerationProgressPercent(clamped),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accentCool,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showStepper && l10n != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AiGenerationStageStepper(
              l10n: l10n!,
              currentStage: stage,
              status: status,
              compact: true,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.percent,
    required this.indeterminate,
    required this.pulse,
  });

  final int percent;
  final bool indeterminate;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    const size = 132.0;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: indeterminate ? 0.35 : percent / 100),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: indeterminate
                    ? CircularProgressIndicator(
                        strokeWidth: 7,
                        color: AppColors.accentCool.withValues(alpha: 0.85),
                      )
                    : CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        backgroundColor:
                            AppColors.inputBorder.withValues(alpha: 0.35),
                        color: AppColors.accentCool,
                      ),
              ),
              if (!indeterminate)
                Text(
                  '$percent%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accentCool.withValues(alpha: pulse ? 1 : 0.75),
                  size: 36,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientProgressBar extends StatefulWidget {
  const _GradientProgressBar({
    required this.value,
    required this.indeterminate,
    required this.pulse,
  });

  final double? value;
  final bool indeterminate;
  final bool pulse;

  @override
  State<_GradientProgressBar> createState() => _GradientProgressBarState();
}

class _GradientProgressBarState extends State<_GradientProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.inputBorder.withValues(alpha: 0.35)),
            if (widget.indeterminate)
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final offset = (_shimmer.value * (w + 80)) - 80;
                      return Stack(
                        children: [
                          Positioned(
                            left: offset,
                            width: 80,
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentCool.withValues(alpha: 0),
                                    AppColors.accentCool.withValues(alpha: 0.85),
                                    AppColors.accentMint.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
            else
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: math.max(widget.value ?? 0, 0.02),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.pulse
                          ? [
                              AppColors.accentCool,
                              AppColors.accentMint,
                              AppColors.accentCool,
                            ]
                          : [AppColors.accentCool, AppColors.accentMint],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
