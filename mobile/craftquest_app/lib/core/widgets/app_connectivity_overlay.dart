import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Global offline banner above all routes.
class AppConnectivityOverlay extends StatelessWidget {
  const AppConnectivityOverlay({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final connectivity = getIt<NetworkConnectivityService>();

    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final showBanner = !connectivity.isOnline && l10n != null;

        return Stack(
          children: [
            if (child != null) child!,
            if (showBanner)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Material(
                  elevation: 6,
                  color: Colors.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        0,
                      ),
                      child: _OfflineBanner(l10n: l10n),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: AppColors.accentGold,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noInternetBannerTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.noInternetBannerMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
