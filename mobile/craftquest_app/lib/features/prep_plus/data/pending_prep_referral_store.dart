import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingPrepReferral {
  const PendingPrepReferral({
    required this.slug,
    this.referralCode,
    required this.capturedAt,
  });

  final String slug;
  final String? referralCode;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        if (referralCode != null) 'referralCode': referralCode,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };

  factory PendingPrepReferral.fromJson(Map<String, dynamic> json) {
    return PendingPrepReferral(
      slug: json['slug'] as String? ?? '',
      referralCode: json['referralCode'] as String?,
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class PendingPrepReferralStore {
  PendingPrepReferralStore(this._preferencesFuture);

  static const _storageKey = 'pending_prep_referral';
  static const _maxAge = Duration(days: 30);

  final Future<SharedPreferences> _preferencesFuture;

  Future<void> save(PendingPrepReferral referral) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_storageKey, jsonEncode(referral.toJson()));
  }

  Future<PendingPrepReferral?> read() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final referral = PendingPrepReferral.fromJson(decoded);
      if (referral.slug.isEmpty) {
        await clear();
        return null;
      }

      if (DateTime.now().toUtc().difference(referral.capturedAt.toUtc()) >
          _maxAge) {
        await clear();
        return null;
      }

      return referral;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _preferencesFuture;
    await prefs.remove(_storageKey);
  }
}
