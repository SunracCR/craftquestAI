import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:craftquest_app/features/auth/presentation/join_launch.dart';
import 'package:flutter/foundation.dart';

/// Captures join deep links and exposes a pending share code for routing.
class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _pendingJoinCode;

  String? get pendingJoinCode => _pendingJoinCode;

  String? consumePendingJoinCode() {
    final code = _pendingJoinCode;
    _pendingJoinCode = null;
    return code;
  }

  Future<void> initialize({void Function(String code)? onJoinCode}) async {
    if (kIsWeb) {
      final webCode = readWebJoinCode();
      if (webCode != null) {
        _pendingJoinCode = webCode;
        onJoinCode?.call(webCode);
      }
      return;
    }

    try {
      final initial = await _appLinks.getInitialLink();
      _captureUri(initial, onJoinCode);
      _subscription = _appLinks.uriLinkStream.listen(
        (uri) => _captureUri(uri, onJoinCode),
      );
    } catch (_) {
      // Deep links are best-effort on unsupported platforms.
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _captureUri(Uri? uri, void Function(String code)? onJoinCode) {
    final code = parseJoinCode(uri);
    if (code == null) {
      return;
    }

    _pendingJoinCode = code;
    onJoinCode?.call(code);
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
