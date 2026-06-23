import 'package:craftquest_app/core/assets/audio_assets.dart';
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
    this.enableMusic = false,
    this.enableSoundEffects = true,
    this.musicTrackIndex = 0,
    this.onMusicChanged,
    this.onSoundEffectsChanged,
    this.onMusicTrackChanged,
    this.randomizeQuestionsHint,
    this.showTimerOption = true,
    this.showRandomizeOption = true,
    this.showMusicOption = true,
    this.showSoundEffectsOption = true,
  });

  final bool randomizeQuestions;
  final bool showTimer;
  final bool enableMusic;
  final bool enableSoundEffects;
  final int musicTrackIndex;
  final String? randomizeQuestionsHint;
  final bool showTimerOption;
  final bool showRandomizeOption;
  final bool showMusicOption;
  final bool showSoundEffectsOption;
  final ValueChanged<bool> onRandomizeQuestionsChanged;
  final ValueChanged<bool> onShowTimerChanged;
  final ValueChanged<bool>? onMusicChanged;
  final ValueChanged<bool>? onSoundEffectsChanged;
  final ValueChanged<int>? onMusicTrackChanged;

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

    if (showMusicOption && onMusicChanged != null) {
      addDivider();
      tiles.add(
        _OptionSwitchTile(
          icon: Icons.music_note_rounded,
          iconColor: AppColors.accentGold,
          title: l10n.practiceBackgroundMusicLabel,
          subtitle: l10n.practiceBackgroundMusicHint,
          value: enableMusic,
          onChanged: onMusicChanged!,
        ),
      );
      if (enableMusic && onMusicTrackChanged != null) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _MusicTrackSelector(
              trackIndex: musicTrackIndex.clamp(0, AudioAssets.trackCount - 1),
              onChanged: onMusicTrackChanged!,
            ),
          ),
        );
      }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: l10n.practiceOptionsTitle),
        const SizedBox(height: AppSpacing.xs),
        AppSectionCard(
          padding: EdgeInsets.zero,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

class _MusicTrackSelector extends StatelessWidget {
  const _MusicTrackSelector({
    required this.trackIndex,
    required this.onChanged,
  });

  final int trackIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.practiceSelectMusicTrackLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<int>(
          value: trackIndex,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.25),
              ),
            ),
          ),
          items: List.generate(
            AudioAssets.trackCount,
            (index) => DropdownMenuItem(
              value: index,
              child: Text(AudioAssets.musicTrackLabel(index)),
            ),
          ),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
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
