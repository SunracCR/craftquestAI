import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Practice settings shown before starting a session (e.g. on quiz detail).
class PracticeLaunchOptionsCard extends StatelessWidget {
  const PracticeLaunchOptionsCard({
    super.key,
    required this.randomizeQuestions,
    required this.showTimer,
    required this.onRandomizeQuestionsChanged,
    required this.onShowTimerChanged,
    this.enableSoundEffects = true,
    this.onSoundEffectsChanged,
    this.randomizeQuestionsHint,
    this.showTimerOption = true,
    this.showRandomizeOption = true,
    this.showSoundEffectsOption = true,
    this.showSectionTitle = true,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableSoundEffects;
  final String? randomizeQuestionsHint;
  final bool showTimerOption;
  final bool showRandomizeOption;
  final bool showSoundEffectsOption;
  final bool showSectionTitle;
  final ValueChanged<bool> onRandomizeQuestionsChanged;
  final ValueChanged<bool> onShowTimerChanged;
  final ValueChanged<bool>? onSoundEffectsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tiles = <Widget>[];

    void addDivider() {
      if (tiles.isNotEmpty) {
        tiles.add(
          Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        );
      }
    }

    if (showRandomizeOption) {
      tiles.add(
        _OptionSwitchTile(
          icon: Icons.shuffle_rounded,
          iconColor: AppColors.accentViolet,
          title: l10n.practiceRandomizeQuestionsLabel,
          subtitle:
              randomizeQuestionsHint ?? l10n.practiceRandomizeQuestionsHint,
          value: randomizeQuestions,
          onChanged: onRandomizeQuestionsChanged,
        ),
      );
    }

    if (showTimerOption) {
      addDivider();
      tiles.add(
        _OptionSwitchTile(
          icon: Icons.timer_outlined,
          iconColor: AppColors.accentCool,
          title: l10n.practiceShowTimerLabel,
          subtitle: l10n.practiceShowTimerHint,
          value: showTimer,
          onChanged: onShowTimerChanged,
        ),
      );
    }

    if (showSoundEffectsOption && onSoundEffectsChanged != null) {
      addDivider();
      tiles.add(
        _OptionSwitchTile(
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.accentMint,
          title: l10n.practiceSoundEffectsLabel,
          subtitle: l10n.practiceSoundEffectsHint,
          value: enableSoundEffects,
          onChanged: onSoundEffectsChanged!,
        ),
      );
    }

    final card = AppSectionCard(
      padding: EdgeInsets.zero,
      child: Column(children: tiles),
    );

    if (!showSectionTitle) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: l10n.practiceOptionsTitle),
        const SizedBox(height: AppSpacing.xs),
        card,
      ],
    );
  }
}

class _OptionSwitchTile extends StatelessWidget {
  const _OptionSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      secondary: DecoratedBox(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
