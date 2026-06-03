import 'package:craftquest_app/core/compliance/age_signal_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Play Age Signals API (Texas SB 2420) vía MethodChannel en Android.
class AgeSignalService {
  AgeSignalService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.craftquestai.app/age_signals');

  static const String prefsKeyRequiresParentalConsent =
      'requires_parental_consent';

  static const String prefsKeyLastUserStatus = 'age_signal_last_user_status';

  static const String playStorePackageId = 'com.craftquestai.craftquestai_app';

  final MethodChannel _channel;

  /// Consulta Play Age Signals y persiste el resultado en [SharedPreferences].
  Future<AgeSignalResult> checkAndPersist() async {
    final result = await checkAgeSignals();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      prefsKeyRequiresParentalConsent,
      result.requiresParentalConsent,
    );
    final status = result.userStatus;
    if (status == null || status.isEmpty) {
      await prefs.remove(prefsKeyLastUserStatus);
    } else {
      await prefs.setString(prefsKeyLastUserStatus, status);
    }
    return result;
  }

  /// Llama a la API nativa (solo Android con Google Play).
  Future<AgeSignalResult> checkAgeSignals() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return const AgeSignalResult(requiresParentalConsent: false);
    }

    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkAgeSignals',
      );
      if (raw == null) {
        return const AgeSignalResult(requiresParentalConsent: false);
      }
      return AgeSignalResult.fromMap(raw);
    } on MissingPluginException {
      return const AgeSignalResult(requiresParentalConsent: false);
    } on PlatformException catch (e) {
      return AgeSignalResult(
        requiresParentalConsent: false,
        errorCode: int.tryParse(e.code),
        errorMessage: e.message,
      );
    }
  }

  /// Valor guardado tras el último [checkAndPersist] (por defecto `false`).
  Future<bool> requiresParentalConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKeyRequiresParentalConsent) ?? false;
  }

  Future<String?> lastUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKeyLastUserStatus);
  }

  Future<void> clearStoredConsentFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyRequiresParentalConsent);
    await prefs.remove(prefsKeyLastUserStatus);
  }
}
