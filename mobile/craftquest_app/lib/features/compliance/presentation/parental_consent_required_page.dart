import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/brand_logo_mark.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de bloqueo cuando Play Age Signals indica consentimiento parental.
class ParentalConsentRequiredPage extends StatefulWidget {
  const ParentalConsentRequiredPage({
    super.key,
    required this.userStatus,
    required this.onRecheckComplete,
  });

  final String? userStatus;
  final ValueChanged<bool> onRecheckComplete;

  @override
  State<ParentalConsentRequiredPage> createState() =>
      _ParentalConsentRequiredPageState();
}

class _ParentalConsentRequiredPageState extends State<ParentalConsentRequiredPage> {
  final _ageSignals = getIt<AgeSignalService>();
  bool _rechecking = false;

  String _message(AppLocalizations l10n) {
    switch (widget.userStatus) {
      case 'SUPERVISED_APPROVAL_PENDING':
        return l10n.parentalConsentBodyPending;
      case 'SUPERVISED_APPROVAL_DENIED':
        return l10n.parentalConsentBodyDenied;
      case 'UNKNOWN':
        return l10n.parentalConsentBodyUnknown;
      default:
        return l10n.parentalConsentBodyDefault;
    }
  }

  Future<void> _openPlayStore() async {
    final marketUri = Uri.parse(
      'market://details?id=${AgeSignalService.playStorePackageId}',
    );
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=${AgeSignalService.playStorePackageId}',
    );
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _recheck() async {
    if (_rechecking) {
      return;
    }
    setState(() => _rechecking = true);
    try {
      final result = await _ageSignals.checkAndPersist();
      if (!mounted) {
        return;
      }
      widget.onRecheckComplete(!result.requiresParentalConsent);
    } finally {
      if (mounted) {
        setState(() => _rechecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthPremiumBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AuthPremiumCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandLogoMark(size: 96)),
                      const SizedBox(height: AppSpacing.md),
                      Icon(
                        Icons.family_restroom_rounded,
                        size: 40,
                        color: AppColors.accentGold.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.parentalConsentTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _message(l10n),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppGradientPrimaryButton(
                        label: l10n.parentalConsentRecheckAction,
                        icon: Icons.refresh_rounded,
                        isLoading: _rechecking,
                        onPressed: _recheck,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSecondaryButton(
                        label: l10n.parentalConsentOpenPlayStore,
                        icon: Icons.shop_rounded,
                        onPressed: _rechecking ? null : _openPlayStore,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
