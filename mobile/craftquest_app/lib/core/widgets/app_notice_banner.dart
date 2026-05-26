import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppNoticeVariant { info, warning, success, error }

/// Banner inline estandarizado para avisos informativos, advertencias y éxito.
///
/// Usa superficies oscuras sobre el tema teal para garantizar contraste legible
/// (no combina texto claro con fondo sand/beige).
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    super.key,
    required this.message,
    this.variant = AppNoticeVariant.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppNoticeVariant variant;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _accentColor => switch (variant) {
        AppNoticeVariant.info => AppColors.accentGold,
        AppNoticeVariant.warning => AppColors.warning,
        AppNoticeVariant.success => AppColors.accentMint,
        AppNoticeVariant.error => AppColors.error,
      };

  Color get _backgroundColor => switch (variant) {
        AppNoticeVariant.info => AppColors.surfaceHighlight,
        _ => AppColors.surface,
      };

  IconData get _defaultIcon => switch (variant) {
        AppNoticeVariant.info => Icons.info_outline_rounded,
        AppNoticeVariant.warning => Icons.warning_amber_rounded,
        AppNoticeVariant.success => Icons.check_circle_outline_rounded,
        AppNoticeVariant.error => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final resolvedIcon = icon ?? _defaultIcon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(resolvedIcon, color: accent, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
