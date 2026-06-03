import 'package:craftquest_app/core/assets/brand_assets.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Marca visual CraftQuest (asset o icono de respaldo).
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = 112,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        BrandAssets.logo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _BrandLogoMarkFallback(size: size),
      ),
    );
  }
}

class _BrandLogoMarkFallback extends StatelessWidget {
  const _BrandLogoMarkFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    final padding = size * 0.2;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Icon(
          Icons.school_rounded,
          color: AppColors.textPrimary,
          size: iconSize,
        ),
      ),
    );
  }
}
