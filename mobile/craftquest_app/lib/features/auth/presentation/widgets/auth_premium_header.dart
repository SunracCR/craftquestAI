import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/brand_logo_mark.dart';
import 'package:flutter/material.dart';

/// Cabecera de marca para login/registro (logo + títulos).
class AuthPremiumHeader extends StatelessWidget {
  const AuthPremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.dense = false,
    this.logoSize = 160,
  });

  final String title;
  final String? subtitle;

  /// Menos espacio vertical entre logo y textos.
  final bool dense;

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gapAfterLogo = dense ? 8.0 : 12.0;
    final gapAfterTitle = dense ? 6.0 : 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogoMark(size: logoSize),
        SizedBox(height: gapAfterLogo),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: gapAfterTitle),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: dense ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: dense ? 13 : null,
            ),
          ),
        ],
      ],
    );
  }
}
