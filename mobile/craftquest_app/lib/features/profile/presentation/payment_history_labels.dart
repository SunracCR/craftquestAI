import 'package:craftquest_app/l10n/app_localizations.dart';

/// Localized labels for purchase history rows.
class PaymentHistoryLabels {
  PaymentHistoryLabels(this.l10n);

  final AppLocalizations l10n;

  String statusLabel(String status) {
    switch (status) {
      case 'validated':
        return l10n.paymentPurchaseStatusValidated;
      case 'pending':
        return l10n.paymentPurchaseStatusPending;
      case 'rejected':
        return l10n.paymentPurchaseStatusRejected;
      case 'refunded':
        return l10n.paymentPurchaseStatusRefunded;
      case 'cancelled':
        return l10n.paymentPurchaseStatusCancelled;
      default:
        return status;
    }
  }

  String providerLabel(String providerCode) {
    switch (providerCode) {
      case 'paypal':
        return l10n.paymentProviderPayPal;
      case 'google_play':
        return l10n.paymentProviderGooglePlay;
      case 'app_store':
        return l10n.paymentProviderAppStore;
      default:
        return l10n.paymentProviderOther;
    }
  }

  String productTypeLabel(String productType) {
    switch (productType) {
      case 'subscription':
        return l10n.paymentProductTypeSubscription;
      case 'prep_access':
        return l10n.paymentProductTypePrepAccess;
      case 'ai_credits':
        return l10n.paymentProductTypeAiCredits;
      case 'share_codes':
        return l10n.paymentProductTypeShareCodes;
      case 'curated_package':
        return l10n.paymentProductTypeCuratedPackage;
      case 'teacher_seats':
        return l10n.paymentProductTypeTeacherSeats;
      default:
        return l10n.paymentProductTypeOther;
    }
  }
}
