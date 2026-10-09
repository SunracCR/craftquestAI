import 'package:craftquest_app/core/compliance/age_signal_service.dart';
import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caché en memoria de flags de cumplimiento para evitar spinners en cascada al arrancar.
class CompliancePrefCache extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _ready = false;

  bool ageCollected = false;
  bool isMinor = false;
  bool parentalBlocked = false;
  String? parentalConsentReason;

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
    isMinor = prefs.getBool(AgeCollectionStorage.minorKey) ?? false;
    parentalBlocked =
        prefs.getBool(AgeSignalService.prefsKeyRequiresParentalConsent) ??
            false;
    parentalConsentReason =
        prefs.getString(AgeSignalService.prefsKeyLastConsentReason);
  }

  void markAgeCollected({required bool isMinor}) {
    ageCollected = true;
    this.isMinor = isMinor;
    notifyListeners();
  }

  void clearAgeCollected() {
    ageCollected = false;
    isMinor = false;
    notifyListeners();
  }

  void updateParentalBlocked({
    required bool blocked,
    String? consentReason,
  }) {
    parentalBlocked = blocked;
    parentalConsentReason = consentReason;
  }
}
