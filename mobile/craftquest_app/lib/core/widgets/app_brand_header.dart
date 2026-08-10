import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/brand_logo_mark.dart';
import 'package:flutter/material.dart';

/// Cabecera de marca para pantallas de autenticación y compliance.
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize,
  });

  final String title;
  final String? subtitle;

  /// Si es null, se calcula en proporción al [headlineSmall] del título.
  final double? logoSize;

  double _resolveLogoSize(TextTheme textTheme) {
    if (logoSize != null) {
      return logoSize!;
    }
    final titleSize = textTheme.headlineSmall?.fontSize ?? 24;
    return (titleSize * 7.25).clamp(140.0, 188.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final resolvedLogoSize = _resolveLogoSize(textTheme);
    final gapAfterLogo = (resolvedLogoSize * 0.08).clamp(10.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogoMark(size: resolvedLogoSize),
        SizedBox(height: gapAfterLogo),
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}
