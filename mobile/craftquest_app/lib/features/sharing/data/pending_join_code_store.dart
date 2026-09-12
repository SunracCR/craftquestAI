import 'package:shared_preferences/shared_preferences.dart';

/// Persists a join code until the deep link flow completes successfully.
class PendingJoinCodeStore {
  PendingJoinCodeStore(this._preferencesFuture);

  static const _storageKey = 'pending_join_code';
  static const _maxAge = Duration(days: 7);

  final Future<SharedPreferences> _preferencesFuture;

  Future<void> save(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }
    final prefs = await _preferencesFuture;
    await prefs.setStringList(_storageKey, [
      normalized,
      DateTime.now().toUtc().toIso8601String(),
    ]);
  }

  Future<String?> read() async {
    final prefs = await _preferencesFuture;
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final code = raw.first.trim();
    if (code.isEmpty) {
      await clear();
      return null;
    }

    if (raw.length >= 2) {
      final capturedAt = DateTime.tryParse(raw[1]);
      if (capturedAt != null &&
          DateTime.now().toUtc().difference(capturedAt.toUtc()) > _maxAge) {
        await clear();
        return null;
      }
    }

    return code;
  }

  Future<void> clear() async {
    final prefs = await _preferencesFuture;
    await prefs.remove(_storageKey);
  }
}
