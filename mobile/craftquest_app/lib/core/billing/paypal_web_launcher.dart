import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPayPalApproval(Uri uri) {
  if (kIsWeb) {
    return launchUrl(uri, webOnlyWindowName: '_self');
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
