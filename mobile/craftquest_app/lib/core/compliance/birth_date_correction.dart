import 'package:craftquest_app/core/compliance/age_collection_controller.dart';
import 'package:craftquest_app/core/compliance/age_collection_policy.dart';
import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/compliance/child_experience.dart';
import 'package:craftquest_app/core/compliance/neutral_birth_date_fields.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/services/push_notification_service.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flujos reutilizables para corregir la fecha de nacimiento.
abstract final class BirthDateCorrection {
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (birthDate.month > today.month ||
        (birthDate.month == today.month && birthDate.day > today.day)) {
      age--;
    }
    return age;
  }

  static bool isMinor(DateTime birthDate) =>
      calculateAge(birthDate) <
      AgeCollectionStorage.minimumAgeWithoutParentalConsent;

  /// Pide día, mes y año. Si [initialDate] es nulo, los campos quedan vacíos.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showNeutralBirthDateDialog(context, initialDate: initialDate);
  }

  /// Guarda en el dispositivo y, si [syncToAccount], actualiza el perfil en API.
  static Future<void> apply(
    BuildContext context,
    DateTime birthDate, {
    bool syncToAccount = false,
  }) async {
    await getIt<AgeCollectionStorage>().saveDateOfBirth(birthDate);
    await _syncPushWithAge();
    if (syncToAccount) {
      await getIt<AuthRepository>().updateProfile(dateOfBirth: birthDate);
    }
  }

  static Future<void> _syncPushWithAge() async {
    final push = getIt<PushNotificationService>();
    if (ChildExperience.isActive) {
      await push.stopForChildExperience();
      return;
    }
    if (kIsWeb) {
      return;
    }
    await push.initializeDeferred();
  }

  /// Limpia el almacenamiento local y vuelve a la pantalla inicial de edad.
  ///
  /// Solo aplica en Android; en iOS/web no se exige DOB (Guideline 5.1.1(v)).
  static Future<void> requestFullAgeScreen() async {
    if (!AgeCollectionPolicy.requiresStartupAgeGate) {
      return;
    }
    await getIt<AgeCollectionController>().requestRecollection();
  }
}
