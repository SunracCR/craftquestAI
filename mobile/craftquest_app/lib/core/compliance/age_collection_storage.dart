import 'package:craftquest_app/core/compliance/compliance_pref_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la fecha de nacimiento recogida en la pantalla neutral de edad.
class AgeCollectionStorage {
  static const collectedKey = 'age_collection_completed';
  static const _dobKey = 'age_collection_date_of_birth';
  static const _minorKey = 'age_collection_is_minor';

  AgeCollectionStorage(this._cache);

  final CompliancePrefCache _cache;

  static const minimumAgeWithoutParentalConsent = 13;

  Future<bool> hasCollectedAge() async {
    if (_cache.isReady) {
      return _cache.ageCollected;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(collectedKey) ?? false;
  }

  Future<DateTime?> getDateOfBirth() async {
    final prefs = _cache.isReady
        ? _cache.prefs
        : await SharedPreferences.getInstance();
    final raw = prefs.getString(_dobKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<bool> isMinor() async {
    final prefs = _cache.isReady
        ? _cache.prefs
        : await SharedPreferences.getInstance();
    return prefs.getBool(_minorKey) ?? false;
  }

  Future<void> saveDateOfBirth(DateTime dateOfBirth) async {
    final prefs = _cache.isReady
        ? _cache.prefs
        : await SharedPreferences.getInstance();
    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    if (dateOfBirth.month > today.month ||
        (dateOfBirth.month == today.month && dateOfBirth.day > today.day)) {
      age--;
    }

    await prefs.setBool(collectedKey, true);
    await prefs.setString(_dobKey, dateOfBirth.toIso8601String());
    await prefs.setBool(
      _minorKey,
      age < minimumAgeWithoutParentalConsent,
    );
    if (_cache.isReady) {
      _cache.markAgeCollected();
    }
  }

  /// Borra la fecha guardada para volver a mostrar la pantalla inicial de edad.
  Future<void> clear() async {
    final prefs = _cache.isReady
        ? _cache.prefs
        : await SharedPreferences.getInstance();
    await prefs.remove(collectedKey);
    await prefs.remove(_dobKey);
    await prefs.remove(_minorKey);
    if (_cache.isReady) {
      _cache.clearAgeCollected();
    }
  }
}
