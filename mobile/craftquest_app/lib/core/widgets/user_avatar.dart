import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/profile/domain/avatar_catalog.dart';
import 'package:flutter/material.dart';

/// Avatar del usuario según [avatarId] del perfil (icono + color del catálogo).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarId,
    this.size = 40,
    this.selected = false,
  });

  final String? avatarId;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final option = AvatarOption.resolve(avatarId);
    final ringColor = selected ? AppColors.accentMint : option.color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            option.color.withValues(alpha: 0.45),
            option.color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: ringColor.withValues(alpha: selected ? 1 : 0.55),
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: option.color.withValues(alpha: 0.28),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Icon(
        option.icon,
        size: size * 0.5,
        color: option.color,
      ),
    );
  }
}
