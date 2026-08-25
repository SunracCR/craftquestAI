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
    PurchaseFailureReason.storeError => _storeErrorMessage(l10n, failure),
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

String _storeErrorMessage(AppLocalizations l10n, PurchaseFailed failure) {
  final message = failure.message;
  if (message != null &&
      message.toLowerCase().contains('pending transaction for the same product')) {
    return l10n.purchasePendingStoreTransaction;
  }
  return message ?? l10n.purchaseFailed;
}
