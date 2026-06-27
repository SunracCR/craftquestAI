import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:craftquest_app/features/auth/presentation/account_link_launch.dart';
import 'package:craftquest_app/features/auth/presentation/join_launch.dart';
import 'package:flutter/foundation.dart';

/// Captures join and account deep links for routing.
class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _pendingJoinCode;
  PendingAccountLink? _pendingAccountLink;

  String? get pendingJoinCode => _pendingJoinCode;

  PendingAccountLink? get pendingAccountLink => _pendingAccountLink;

  String? consumePendingJoinCode() {
    final code = _pendingJoinCode;
    _pendingJoinCode = null;
    return code;
  }

  PendingAccountLink? consumePendingAccountLink() {
    final link = _pendingAccountLink;
    _pendingAccountLink = null;
    return link;
  }

  void clearPendingLinks() {
    _pendingJoinCode = null;
    _pendingAccountLink = null;
  }

  Future<void> initialize({
    void Function(String code)? onJoinCode,
    void Function(PendingAccountLink link)? onAccountLink,
  }) async {
    if (kIsWeb) {
      final webCode = readWebJoinCode();
      if (webCode != null) {
        _pendingJoinCode = webCode;
        onJoinCode?.call(webCode);
      }

      final webAccountLink = readWebAccountLink();
      if (webAccountLink != null) {
        _pendingAccountLink = webAccountLink;
        onAccountLink?.call(webAccountLink);
      }
      return;
    }

    try {
      final initial = await _appLinks.getInitialLink();
      _captureUri(initial, onJoinCode, onAccountLink);
      _subscription = _appLinks.uriLinkStream.listen(
        (uri) => _captureUri(uri, onJoinCode, onAccountLink),
      );
    } catch (_) {
      // Deep links are best-effort on unsupported platforms.
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _captureUri(
    Uri? uri,
    void Function(String code)? onJoinCode,
    void Function(PendingAccountLink link)? onAccountLink,
  ) {
    final accountLink = parseAccountLink(uri);
    if (accountLink != null) {
      _pendingAccountLink = accountLink;
      onAccountLink?.call(accountLink);
      return;
    }

    final code = parseJoinCode(uri);
    if (code == null) {
      return;
    }

    _pendingJoinCode = code;
    onJoinCode?.call(code);
  }

  static PendingAccountLink? parseAccountLink(Uri? uri) {
    if (uri == null) {
      return null;
    }

    if (uri.scheme == 'craftquest') {
      final host = uri.host.toLowerCase();
      final kind = _kindFromPath(host);
      if (kind != null) {
        final segment =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        final token = segment.trim();
        if (token.length >= 20) {
          return PendingAccountLink(kind: kind, token: token);
        }
      }
    }

    if (uri.pathSegments.length >= 2) {
      final kind = _kindFromPath(uri.pathSegments.first);
      if (kind != null) {
        final token = uri.pathSegments[1].trim();
        if (token.length >= 20) {
          return PendingAccountLink(kind: kind, token: token);
        }
      }
    }

    final tokenParam = uri.queryParameters['token']?.trim();
    if (tokenParam != null && tokenParam.length >= 20) {
      final path = uri.path.toLowerCase();
      if (path.contains('verify-email')) {
        return PendingAccountLink(
          kind: AccountLinkKind.verifyEmail,
          token: tokenParam,
        );
      }
      if (path.contains('reset-password')) {
        return PendingAccountLink(
          kind: AccountLinkKind.resetPassword,
          token: tokenParam,
        );
      }
      if (path.contains('confirm-password-change')) {
        return PendingAccountLink(
          kind: AccountLinkKind.confirmPasswordChange,
          token: tokenParam,
        );
      }
    }

    return null;
  }

  static AccountLinkKind? _kindFromPath(String segment) {
    switch (segment.toLowerCase()) {
      case 'verify-email':
        return AccountLinkKind.verifyEmail;
      case 'reset-password':
        return AccountLinkKind.resetPassword;
      case 'confirm-password-change':
        return AccountLinkKind.confirmPasswordChange;
      default:
        return null;
    }
  }

  static String? parseJoinCode(Uri? uri) {
    if (uri == null) {
      return null;
    }

    if (uri.scheme == 'craftquest' && uri.host == 'join') {
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return _normalizeCode(segment);
    }

    final codeParam = uri.queryParameters['code'];
    if (codeParam != null && codeParam.trim().isNotEmpty) {
      return _normalizeCode(codeParam);
    }

    if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first.toLowerCase() == 'join') {
      return _normalizeCode(uri.pathSegments[1]);
    }

    return null;
  }

  static String? _normalizeCode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (!RegExp(r'^CQ-\d{6}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }
}
