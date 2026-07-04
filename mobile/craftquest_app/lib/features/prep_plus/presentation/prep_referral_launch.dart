import 'package:flutter/foundation.dart';

class PendingPrepReferralLink {
  const PendingPrepReferralLink({
    required this.slug,
    this.referralCode,
  });

  final String slug;
  final String? referralCode;

  String get dedupeKey => '${slug.toLowerCase()}:${referralCode ?? ''}';
}

PendingPrepReferralLink? readWebPrepReferral() {
  if (!kIsWeb) {
    return null;
  }

  final uri = Uri.base;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  String? slug;
  if (segments.isNotEmpty && segments.first.toLowerCase() == 'prep') {
    if (segments.length >= 2) {
      slug = segments[1].trim().toLowerCase();
    }
  }

  if (slug == null || slug.isEmpty) {
    return null;
  }

  final referralCode = _normalizeReferralCode(uri.queryParameters['ref']);
  return PendingPrepReferralLink(slug: slug, referralCode: referralCode);
}

String? _normalizeReferralCode(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final normalized = raw.trim().toUpperCase();
  if (!RegExp(r'^PR-\d{6}$').hasMatch(normalized)) {
    return null;
  }

  return normalized;
}
