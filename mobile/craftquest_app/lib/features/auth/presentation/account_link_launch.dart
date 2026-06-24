import 'package:flutter/foundation.dart';

enum AccountLinkKind {
  verifyEmail,
  resetPassword,
  confirmPasswordChange,
}

class PendingAccountLink {
  const PendingAccountLink({
    required this.kind,
    required this.token,
  });

  final AccountLinkKind kind;
  final String token;
}

/// Reads account-link tokens from the Flutter web URL.
PendingAccountLink? readWebAccountLink() {
  if (!kIsWeb) {
    return null;
  }

  final uri = Uri.base;
  final path = uri.path.toLowerCase();

  AccountLinkKind? kind;
  if (path.contains('verify-email')) {
    kind = AccountLinkKind.verifyEmail;
  } else if (path.contains('reset-password')) {
    kind = AccountLinkKind.resetPassword;
  } else if (path.contains('confirm-password-change')) {
    kind = AccountLinkKind.confirmPasswordChange;
  }

  if (kind == null) {
    return null;
  }

  var token = uri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty) {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      token = segments.last.trim();
    }
  }

  if (token == null || token.length < 20) {
    return null;
  }

  return PendingAccountLink(kind: kind, token: token);
}

/// Legacy helper kept for existing reset-password web URLs with `?token=`.
String? readWebPasswordResetToken() {
  final link = readWebAccountLink();
  if (link?.kind == AccountLinkKind.resetPassword) {
    return link!.token;
  }
  return null;
}
