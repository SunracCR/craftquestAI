import 'package:flutter/foundation.dart';

/// Política de recogida de edad por plataforma.
///
/// Web e iOS: no exigir fecha de nacimiento (Guideline 5.1.1(v) en iOS).
/// Android: mantener [AgeScreen] por audiencia mixta / Play Age Signals.
abstract final class AgeCollectionPolicy {
  /// Pantalla de edad obligatoria al abrir la app (solo Android nativo).
  static bool get requiresStartupAgeGate {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Campo de fecha de nacimiento obligatorio en registro por email.
  static bool get requiresRegistrationBirthDate => requiresStartupAgeGate;

  /// Ajustes de fecha de nacimiento en perfil / login (solo Android).
  static bool get showsBirthDateSettings => requiresStartupAgeGate;
}
