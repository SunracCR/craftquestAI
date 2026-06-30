import 'package:craftquest_app/core/compliance/age_collection_controller.dart';
import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
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

  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final initial = initialDate ?? DateTime(now.year - 16, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.ageScreenBirthDateLabel,
    );
  }

  /// Guarda en el dispositivo y, si [syncToAccount], actualiza el perfil en API.
  static Future<void> apply(
    BuildContext context,
    DateTime birthDate, {
    bool syncToAccount = false,
  }) async {
    await getIt<AgeCollectionStorage>().saveDateOfBirth(birthDate);
    if (syncToAccount) {
      await getIt<AuthRepository>().updateProfile(dateOfBirth: birthDate);
    }
  }

  /// Limpia el almacenamiento local y vuelve a la pantalla inicial de edad.
  static Future<void> requestFullAgeScreen() async {
    await getIt<AgeCollectionController>().requestRecollection();
  }
}
