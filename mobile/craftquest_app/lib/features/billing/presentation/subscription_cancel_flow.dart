import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Flujo de cancelación según proveedor (PayPal vs tiendas móviles).
abstract final class SubscriptionCancelFlow {
  static bool isMobileStore(String? providerCode) =>
      providerCode == 'google_play' || providerCode == 'app_store';

  static Future<void> showCancelDialog({
    required BuildContext context,
    required String? providerCode,
    required Future<void> Function() onCompleted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (isMobileStore(providerCode)) {
      await _showMobileStoreDialog(
        context: context,
        providerCode: providerCode!,
        onCompleted: onCompleted,
      );
      return;
    }

    await _showPayPalStyleDialog(
      context: context,
      onCompleted: onCompleted,
      title: l10n.teacherUpgradeCancelTitle,
      message: l10n.teacherUpgradeCancelMessage,
      confirmLabel: l10n.teacherUpgradeCancelConfirm,
      keepLabel: l10n.teacherUpgradeKeepPlan,
    );
  }

  static Future<void> _showMobileStoreDialog({
    required BuildContext context,
    required String providerCode,
    required Future<void> Function() onCompleted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isGoogle = providerCode == 'google_play';
    final message = isGoogle
        ? l10n.billingCancelStoreMessageGoogle
        : l10n.billingCancelStoreMessageApple;
    final openLabel = isGoogle
        ? l10n.billingCancelStoreOpenGooglePlay
        : l10n.billingCancelStoreOpenAppStore;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.billingCancelStoreTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.closeAction,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await openStoreSubscriptionManagement(providerCode);
            },
            child: Text(
              openLabel,
              style: const TextStyle(color: AppColors.accentCool),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    await _showPayPalStyleDialog(
      context: context,
      onCompleted: onCompleted,
      title: l10n.billingCancelStoreSyncTitle,
      message: l10n.billingCancelStoreSyncMessage,
      confirmLabel: l10n.billingCancelStoreSyncConfirm,
      keepLabel: l10n.teacherUpgradeKeepPlan,
    );
  }

  static Future<void> _showPayPalStyleDialog({
    required BuildContext context,
    required Future<void> Function() onCompleted,
    required String title,
    required String message,
    required String confirmLabel,
    required String keepLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              keepLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = getIt<BillingRepository>();
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await repo.cancelSubscription();
      if (!context.mounted) return;
      final accessDate = BillingDisplay.formatSubscriptionDate(
        context,
        result.accessUntil,
      );
      context.showSuccessSnackBar(
        l10n.teacherUpgradeCancelSuccessUntil(accessDate),
      );
      await onCompleted();
    } on DioException catch (e) {
      if (!context.mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  static Future<void> openStoreSubscriptionManagement(String providerCode) async {
    final uri = providerCode == 'google_play'
        ? Uri.parse(
            'https://play.google.com/store/account/subscriptions',
          )
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
