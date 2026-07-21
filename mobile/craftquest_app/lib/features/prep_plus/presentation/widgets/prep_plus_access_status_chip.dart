import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_access_countdown_badge.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pill única de estado de acceso Prep+ (fuente de verdad en detalle).
class PrepPlusAccessStatusChip extends StatelessWidget {
  const PrepPlusAccessStatusChip({
    super.key,
    required this.userAccessState,
    required this.canPractice,
    required this.isLifetimeAccess,
    this.accessExpiresAt,
    required this.formatDate,
    this.onCountdownTap,
  });

  final String userAccessState;
  final bool canPractice;
  final bool isLifetimeAccess;
  final DateTime? accessExpiresAt;
  final String Function(DateTime date) formatDate;
  final VoidCallback? onCountdownTap;

  bool get _isOwned => isLifetimeAccess || userAccessState == 'owned';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isOwned) {
      return _StatusPill(
        label: l10n.prepPlusAccessOwnedBadge,
        foreground: AppColors.accentGold,
        icon: Icons.all_inclusive_rounded,
      );
    }

    if (userAccessState == 'expired') {
      return _StatusPill(
        label: l10n.prepPlusAccessExpired,
        foreground: AppColors.textSecondary,
        icon: Icons.history_rounded,
      );
    }

    if (canPractice && accessExpiresAt != null) {
      final showCountdown = PrepPlusAccessCountdown.shouldShow(
        canPractice: canPractice,
        accessExpiresAt: accessExpiresAt,
      );
      if (showCountdown) {
        return PrepPlusAccessCountdownBadge(
          expiresAt: accessExpiresAt!,
          onTap: onCountdownTap,
          compact: true,
        );
      }
      return _StatusPill(
        label: l10n.prepPlusAccessUntil(formatDate(accessExpiresAt!)),
        foreground: AppColors.accentMint,
        icon: Icons.schedule_rounded,
      );
    }

    if (userAccessState == 'active') {
      return _StatusPill(
        label: l10n.prepPlusAccessActive,
        foreground: AppColors.accentMint,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return _StatusPill(
      label: l10n.prepPlusAccessNone,
      foreground: AppColors.textSecondary,
      icon: Icons.lock_outline_rounded,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
