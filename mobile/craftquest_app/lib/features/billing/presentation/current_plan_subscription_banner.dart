import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/presentation/subscription_cancel_flow.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Banner de plan de suscripción activo con renovación y opción de cancelar.
class CurrentPlanSubscriptionBanner extends StatelessWidget {
  const CurrentPlanSubscriptionBanner({
    super.key,
    required this.planName,
    required this.subscription,
    this.activeMessage,
    this.onCancelPressed,
    this.cancelling = false,
    this.onResumePressed,
    this.resuming = false,
  });

  final String planName;
  final SubscriptionModel subscription;
  final String? activeMessage;
  final VoidCallback? onCancelPressed;
  final bool cancelling;
  final VoidCallback? onResumePressed;
  final bool resuming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = BillingDisplay.activePlanBannerMessage(
      context,
      l10n,
      planName: planName,
      subscription: subscription,
      activeMessage: activeMessage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNoticeBanner(
          message: message,
          variant: AppNoticeVariant.success,
        ),
        if (onResumePressed != null && subscription.canResumeAutoRenew) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: resuming ? null : onResumePressed,
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCool),
            child: resuming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentCool,
                    ),
                  )
                : Text(
                    SubscriptionCancelFlow.isMobileStore(subscription.providerCode)
                        ? l10n.billingResumeStoreTitle
                        : l10n.billingResumeAutoRenewConfirm,
                  ),
          ),
        ],
        if (onCancelPressed != null &&
            subscription.isRecurring &&
            subscription.autoRenewEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: cancelling ? null : onCancelPressed,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : Text(
                    SubscriptionCancelFlow.isMobileStore(subscription.providerCode)
                        ? l10n.billingCancelStoreTitle
                        : l10n.teacherUpgradeCancelConfirm,
                  ),
          ),
        ],
      ],
    );
  }
}
