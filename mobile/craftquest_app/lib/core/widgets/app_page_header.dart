import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Cabecera con gradiente suave para pantallas de contenido.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.14),
              AppColors.accentCool.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
