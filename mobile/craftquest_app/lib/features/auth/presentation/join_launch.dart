import 'package:flutter/foundation.dart';

/// Reads join code from Flutter web URL: `/join?code=CQ-XXXXXX` or `/join/CQ-XXXXXX`.
String? readWebJoinCode() {
  if (!kIsWeb) {
    return null;
  }

  final uri = Uri.base;
  final queryCode = uri.queryParameters['code'];
  if (queryCode != null && queryCode.trim().isNotEmpty) {
    return _normalizeCode(queryCode);
  }

  final segments = uri.pathSegments;
  if (segments.length >= 2 && segments.first.toLowerCase() == 'join') {
    return _normalizeCode(segments[1]);
  }

  if (segments.length == 1 && segments.first.toLowerCase() == 'join') {
    return null;
  }

  return null;
}

String? _normalizeCode(String raw) {
  final normalized = raw.trim().toUpperCase();
  if (!RegExp(r'^CQ-\d{6}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}
