import 'dart:convert';

import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last successful `/api/billing/me` payload per user for instant UI.
class BillingSnapshotStore {
  BillingSnapshotStore(this._preferencesFuture);

  final Future<SharedPreferences> _preferencesFuture;

  static String _keyForUser(String userId) => 'billing.me.$userId';

  Future<UserBillingModel?> read(String userId) async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserBillingModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, Map<String, dynamic> rawJson) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_keyForUser(userId), jsonEncode(rawJson));
  }

  Future<void> clear(String userId) async {
    final prefs = await _preferencesFuture;
    await prefs.remove(_keyForUser(userId));
  }

  Future<void> clearAll() async {
    final prefs = await _preferencesFuture;
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('billing.me.'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
