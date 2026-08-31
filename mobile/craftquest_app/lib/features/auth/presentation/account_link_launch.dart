import 'package:craftquest_app/features/auth/presentation/web_browser_entry_uri_stub.dart'
    if (dart.library.js_interop) 'package:craftquest_app/features/auth/presentation/web_browser_entry_uri_web.dart';
import 'package:flutter/foundation.dart';

enum AccountLinkKind {
  verifyEmail,
  resetPassword,
  confirmPasswordChange,
  parentalConsent,
}

class PendingAccountLink {
  const PendingAccountLink({
    required this.kind,
    required this.token,
  });

  final AccountLinkKind kind;
  final String token;
}

/// Parses account-link tokens from a URI (`/verify-email`, `/parental-consent`, etc.).
PendingAccountLink? parseAccountLinkFromUri(Uri uri) {
  final path = uri.path.toLowerCase();
  final fragment = uri.fragment.trim();

  AccountLinkKind? kind;
  if (_containsAction(path, 'verify-email') ||
      _containsAction(fragment, 'verify-email')) {
    kind = AccountLinkKind.verifyEmail;
  } else if (_containsAction(path, 'reset-password') ||
      _containsAction(fragment, 'reset-password')) {
    kind = AccountLinkKind.resetPassword;
  } else if (_containsAction(path, 'confirm-password-change') ||
      _containsAction(fragment, 'confirm-password-change')) {
    kind = AccountLinkKind.confirmPasswordChange;
  } else if (_containsAction(path, 'parental-consent') ||
      _containsAction(fragment, 'parental-consent')) {
    kind = AccountLinkKind.parentalConsent;
  }

  if (kind == null) {
    return null;
  }

  var token = uri.queryParameters['token']?.trim();
  token ??= _tokenFromFragment(fragment);
  if (token == null || token.isEmpty) {
    token = _tokenFromPathSegments(uri.pathSegments);
  }
  if ((token == null || token.isEmpty) && fragment.isNotEmpty) {
    token = _tokenFromPathSegments(Uri.parse('http://local/$fragment').pathSegments);
  }

  if (token == null || token.length < 20) {
    return null;
  }

  return PendingAccountLink(kind: kind, token: token);
}

/// Reads account-link tokens from the Flutter web URL.
PendingAccountLink? readWebAccountLink() {
  if (!kIsWeb) {
    return null;
  }

  return parseAccountLinkFromUri(getWebBrowserEntryUri());
}

/// Legacy helper kept for existing reset-password web URLs with `?token=`.
String? readWebPasswordResetToken() {
  final link = readWebAccountLink();
  if (link?.kind == AccountLinkKind.resetPassword) {
    return link!.token;
  }
  return null;
}

bool _containsAction(String value, String action) {
  return value.toLowerCase().contains(action);
}

String? _tokenFromFragment(String fragment) {
  if (fragment.isEmpty) {
    return null;
  }

  final queryStart = fragment.indexOf('?');
  if (queryStart >= 0) {
    final query = fragment.substring(queryStart + 1);
    final token = Uri.splitQueryString(query)['token']?.trim();
    if (token != null && token.isNotEmpty) {
      return token;
    }
  }

  return null;
}

String? _tokenFromPathSegments(List<String> segments) {
  if (segments.isEmpty) {
    return null;
  }

  final last = segments.last.trim();
  const knownActions = {
    'verify-email',
    'reset-password',
    'confirm-password-change',
    'parental-consent',
  };
  if (knownActions.contains(last.toLowerCase())) {
    return null;
  }

  return last.isEmpty ? null : last;
}
