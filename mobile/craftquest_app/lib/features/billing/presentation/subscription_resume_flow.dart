import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_cancel_flow.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Flujo para reactivar la renovación automática antes de que venza el periodo.
abstract final class SubscriptionResumeFlow {
  static Future<void> showResumeDialog({
    required BuildContext context,
    required String? providerCode,
    required Future<void> Function() onCompleted,
    Future<void> Function()? onRequiresResubscribe,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (SubscriptionCancelFlow.isMobileStore(providerCode)) {
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
      onRequiresResubscribe: onRequiresResubscribe,
      title: l10n.billingResumeAutoRenewTitle,
      message: l10n.billingResumeAutoRenewMessage,
      confirmLabel: l10n.billingResumeAutoRenewConfirm,
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
        ? l10n.billingResumeStoreMessageGoogle
        : l10n.billingResumeStoreMessageApple;
    final openLabel = isGoogle
        ? l10n.billingCancelStoreOpenGooglePlay
        : l10n.billingCancelStoreOpenAppStore;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.billingResumeStoreTitle,
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
              await SubscriptionCancelFlow.openStoreSubscriptionManagement(
                ctx,
                providerCode,
              );
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
      title: l10n.billingResumeStoreSyncTitle,
      message: l10n.billingResumeStoreSyncMessage,
      confirmLabel: l10n.billingResumeStoreSyncConfirm,
      keepLabel: l10n.teacherUpgradeKeepPlan,
    );
  }

  static Future<void> _showPayPalStyleDialog({
    required BuildContext context,
    required Future<void> Function() onCompleted,
    Future<void> Function()? onRequiresResubscribe,
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
              style: const TextStyle(color: AppColors.accentCool),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = getIt<BillingRepository>();
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await repo.resumeAutoRenew();
      if (!context.mounted) return;

      if (result.requiresResubscribe) {
        await _showRequiresResubscribeDialog(
          context: context,
          onResubscribe: onRequiresResubscribe,
        );
        return;
      }

      if (result.autoRenewEnabled && result.nextRenewalAt != null) {
        final renewalDate = BillingDisplay.formatSubscriptionDate(
          context,
          result.nextRenewalAt!,
        );
        context.showSuccessSnackBar(
          l10n.billingResumeAutoRenewSuccessUntil(renewalDate),
        );
      } else {
        context.showSuccessSnackBar(l10n.billingResumeAutoRenewSuccess);
      }
      await onCompleted();
    } on DioException catch (e) {
      if (!context.mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  static Future<void> _showRequiresResubscribeDialog({
    required BuildContext context,
    Future<void> Function()? onResubscribe,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.billingResumeRequiresResubscribeTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.billingResumeRequiresResubscribeMessage,
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
          if (onResubscribe != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.billingResumeRequiresResubscribeConfirm,
                style: const TextStyle(color: AppColors.accentCool),
              ),
            ),
        ],
      ),
    );

    if (proceed == true && onResubscribe != null) {
      await onResubscribe();
    }
  }
}
