import 'dart:async';

import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/brand_logo_mark.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de bloqueo total cuando la versión instalada quedó por debajo de
/// `minSupportedVersion`. No tiene botón de "más tarde": es la única salida.
class ForceUpdateRequiredPage extends StatelessWidget {
  const ForceUpdateRequiredPage({super.key, required this.requirement});

  final AppVersionRequirement requirement;

  Future<void> _openStore() async {
    final uri = Uri.parse(requirement.updateUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final message = requirement.message?.trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                          Icons.system_update_rounded,
                          size: 40,
                          color: AppColors.accentGold.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.forceUpdateTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          message != null && message.isNotEmpty
                              ? message
                              : l10n.forceUpdateBodyDefault,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppGradientPrimaryButton(
                          label: l10n.forceUpdateAction,
                          icon: Icons.system_update_rounded,
                          onPressed: () {
                            unawaited(_openStore());
                          },
                        ),
                      ],
                    ),
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
