import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void showStorePurchaseFailure(
  BuildContext context,
  PurchaseFailed failure,
) {
  final l10n = AppLocalizations.of(context)!;
  final message = switch (failure.reason) {
    PurchaseFailureReason.storeUnavailable => l10n.storeProductNotConfigured,
    PurchaseFailureReason.productNotFound => l10n.storeProductNotConfigured,
    PurchaseFailureReason.verificationFailed =>
      failure.message ?? l10n.purchaseVerificationFailed,
    PurchaseFailureReason.timeout => l10n.purchaseTimedOut,
    PurchaseFailureReason.cancelled => l10n.purchaseFailed,
    PurchaseFailureReason.duplicateInFlight => l10n.purchaseFailed,
    PurchaseFailureReason.storeError =>
      failure.message ?? l10n.purchaseFailed,
  };

  if (failure.reason == PurchaseFailureReason.cancelled) {
    return;
  }

  context.showErrorSnackBar(message);
}

void showStorePurchaseDeferred(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  context.showInfoSnackBar(l10n.purchaseAwaitingApproval);
}
