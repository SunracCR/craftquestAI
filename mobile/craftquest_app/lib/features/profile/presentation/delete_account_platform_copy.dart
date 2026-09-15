import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

String deleteAccountSubscriptionNotice(AppLocalizations l10n) {
  if (PaymentPlatform.isMobileStorePlatform) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return l10n.deleteAccountSubscriptionNoticeAppStore;
    }
    return l10n.deleteAccountSubscriptionNoticePlayStore;
  }

  return l10n.deleteAccountSubscriptionNoticePayPal;
}
