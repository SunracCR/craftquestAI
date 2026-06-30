import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caché en memoria de flags de cumplimiento para evitar spinners en cascada al arrancar.
class CompliancePrefCache {
  SharedPreferences? _prefs;
  bool _ready = false;

  bool ageCollected = false;
  bool parentalBlocked = false;
  String? parentalUserStatus;

  bool get isReady => _ready;

  SharedPreferences get prefs {
    final cached = _prefs;
    if (cached == null) {
      throw StateError('CompliancePrefCache.warmUp() must complete first.');
    }
    return cached;
  }

  Future<void> warmUp() async {
    if (_ready) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    _reloadFromPrefs();
    _ready = true;
  }

  void _reloadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    ageCollected = prefs.getBool(AgeCollectionStorage.collectedKey) ?? false;
    parentalBlocked =
        prefs.getBool(AgeSignalService.prefsKeyRequiresParentalConsent) ??
            false;
    parentalUserStatus = prefs.getString(AgeSignalService.prefsKeyLastUserStatus);
  }

  void markAgeCollected() {
    ageCollected = true;
  }

  void clearAgeCollected() {
    ageCollected = false;
  }

  void updateParentalBlocked({
    required bool blocked,
    String? userStatus,
  }) {
    parentalBlocked = blocked;
    parentalUserStatus = userStatus;
  }
}
