import 'package:flutter/foundation.dart';

/// Reads `?token=` from the Flutter web URL when path contains `reset-password`.
String? readWebPasswordResetToken() {
  if (!kIsWeb) {
    return null;
  }

  final uri = Uri.base;
  if (!uri.path.contains('reset-password')) {
    return null;
  }

  final token = uri.queryParameters['token'];
  if (token == null || token.trim().isEmpty) {
    return null;
  }

  return token.trim();
}
