import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.icon,
    required this.color,
  });

  final String id;
  final IconData icon;
  final Color color;

  static const String defaultId = 'craft_01';

  static const List<AvatarOption> all = [
    AvatarOption(
      id: 'craft_01',
      icon: Icons.school_rounded,
      color: AppColors.accentMint,
    ),
    AvatarOption(
      id: 'craft_02',
      icon: Icons.psychology_rounded,
      color: AppColors.accentViolet,
    ),
    AvatarOption(
      id: 'craft_03',
      icon: Icons.emoji_events_rounded,
      color: AppColors.accentGold,
    ),
    AvatarOption(
      id: 'craft_04',
      icon: Icons.auto_stories_rounded,
      color: AppColors.accentCool,
    ),
    AvatarOption(
      id: 'craft_05',
      icon: Icons.science_rounded,
      color: AppColors.accentSky,
    ),
    AvatarOption(
      id: 'craft_06',
      icon: Icons.palette_rounded,
      color: AppColors.accent,
    ),
    AvatarOption(
      id: 'craft_07',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.accentWarm,
    ),
    AvatarOption(
      id: 'craft_08',
      icon: Icons.person_rounded,
      color: AppColors.textSecondary,
    ),
    AvatarOption(
      id: 'craft_09',
      icon: Icons.bolt_rounded,
      color: AppColors.teacherAccent,
    ),
    AvatarOption(
      id: 'craft_10',
      icon: Icons.favorite_rounded,
      color: AppColors.error,
    ),
  ];

  static AvatarOption resolve(String? avatarId) {
    return all.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => all.first,
    );
  }
}
