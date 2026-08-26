import 'package:craftquest_app/core/billing/paypal_web_launcher.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the PayPal approval URL and surfaces a visible error when redirect fails.
Future<bool> openPayPalApprovalUrl(
  BuildContext context,
  Uri uri, {
  required AppLocalizations l10n,
}) async {
  if (!kIsWeb && !await canLaunchUrl(uri)) {
    if (context.mounted) {
      context.showErrorSnackBar(l10n.paypalReturnError);
    }
    return false;
  }

  final launched = await launchPayPalApproval(uri);
  if (!launched && context.mounted) {
    context.showErrorSnackBar(l10n.paypalReturnError);
  }
  return launched;
}
