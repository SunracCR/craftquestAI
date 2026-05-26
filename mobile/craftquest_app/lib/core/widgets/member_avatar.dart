import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Avatar de alumno/miembro: icono del catálogo o iniciales como respaldo.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    this.avatarId,
    required this.displayName,
    this.size = 36,
    this.accentColor,
  });

  final String? avatarId;
  final String displayName;
  final double size;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    if (avatarId != null && avatarId!.isNotEmpty) {
      return UserAvatar(avatarId: avatarId, size: size);
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';
    final color = accentColor ?? AppColors.teacherAccent;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
