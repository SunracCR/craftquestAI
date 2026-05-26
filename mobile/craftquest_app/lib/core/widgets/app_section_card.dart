import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Tarjeta de sección sobre fondo dark teal (charcoal por defecto).
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.surface,
    this.padding = AppColors.paddingMd,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      AppCardVariant.surface => AppColors.surface,
      AppCardVariant.highlight => AppColors.surfaceHighlight,
      AppCardVariant.warm => AppColors.surfaceSecondary,
    };

    final borderAlpha = switch (variant) {
      AppCardVariant.warm => 0.15,
      AppCardVariant.highlight => 0.2,
      AppCardVariant.surface => 0.12,
    };

    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        side: BorderSide(
          color: variant == AppCardVariant.highlight
              ? AppColors.accent.withValues(alpha: 0.22)
              : AppColors.textSecondary.withValues(alpha: borderAlpha),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

enum AppCardVariant { surface, highlight, warm }
