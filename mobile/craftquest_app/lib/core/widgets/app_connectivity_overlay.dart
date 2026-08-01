import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/network_connectivity_service.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Global offline indicator above all routes. Compact and dismissible per offline spell.
class AppConnectivityOverlay extends StatefulWidget {
  const AppConnectivityOverlay({
    super.key,
    required this.child,
    this.showOfflineSessionBanner = false,
  });

  final Widget? child;
  final bool showOfflineSessionBanner;

  @override
  State<AppConnectivityOverlay> createState() => _AppConnectivityOverlayState();
}

class _AppConnectivityOverlayState extends State<AppConnectivityOverlay> {
  late final NetworkConnectivityService _connectivity;
  bool _noInternetDismissed = false;
  bool _sessionBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _connectivity = getIt<NetworkConnectivityService>();
    _connectivity.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline) {
      if (_noInternetDismissed || _sessionBannerDismissed) {
        setState(() {
          _noInternetDismissed = false;
          _sessionBannerDismissed = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _connectivity,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        if (l10n == null) {
          return widget.child ?? const SizedBox.shrink();
        }

        final showNoInternet =
            !_connectivity.isOnline && !_noInternetDismissed;
        final showSession =
            widget.showOfflineSessionBanner && !_sessionBannerDismissed;
        final showAnyBanner = showNoInternet || showSession;

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            if (showAnyBanner)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Material(
                  elevation: 4,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showNoInternet)
                            _CompactOfflineBanner(
                              title: l10n.noInternetBannerTitle,
                              icon: Icons.wifi_off_rounded,
                              onDismiss: () {
                                setState(() => _noInternetDismissed = true);
                              },
                              dismissTooltip: l10n.closeAction,
                            ),
                          if (showNoInternet && showSession)
                            const SizedBox(height: AppSpacing.xs),
                          if (showSession)
                            _CompactOfflineBanner(
                              title: l10n.offlineSessionBannerTitle,
                              icon: Icons.cloud_off_rounded,
                              onDismiss: () {
                                setState(() => _sessionBannerDismissed = true);
                              },
                              dismissTooltip: l10n.closeAction,
                            ),
                        ],
                      ),
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

class _CompactOfflineBanner extends StatelessWidget {
  const _CompactOfflineBanner({
    required this.title,
    required this.icon,
    required this.onDismiss,
    required this.dismissTooltip,
  });

  final String title;
  final IconData icon;
  final VoidCallback onDismiss;
  final String dismissTooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.accentGold,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: dismissTooltip,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
