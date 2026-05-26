import 'package:flutter/material.dart';

/// Paleta CraftQuest — no modificar sin actualizar el sistema de diseño.
abstract final class AppColors {
  /// Fondo principal (Dark Teal). Scaffolds y AppBars.
  static const Color background = Color(0xFF1A2F35);

  /// Superficies y tarjetas (Charcoal Gray).
  static const Color surface = Color(0xFF263238);

  /// Superficies secundarias (Warm Sand / Beige). Tarjetas cálidas, no formularios.
  static const Color surfaceSecondary = Color(0xFFCDBCA5);

  /// Borde de campos en reposo.
  static const Color inputBorder = Color(0xFF4A6270);

  /// Acento principal (melocotón). CTAs, selección, progreso, enlaces.
  static const Color accent = Color(0xFFFFB86C);

  /// Tono claro del acento (hover, brillos).
  static const Color accentWarm = Color(0xFFFFD4A0);

  /// Acciones analíticas / información.
  static const Color accentCool = Color(0xFF4ECDC4);

  /// Gradiente CTA (melocotón → dorado).
  static const Color accentGold = Color(0xFFE8C170);

  /// Compartir / códigos.
  static const Color accentViolet = Color(0xFF9B8CFF);

  /// Estado publicado / éxito.
  static const Color accentMint = Color(0xFF6BCB9F);

  /// Fondo del recuadro de archivo Excel cargado (verde profundo).
  static const Color importFileReadySurface = Color(0xFF1A3F36);

  /// Fondo secundario del recuadro de archivo Excel cargado.
  static const Color importFileReadySurfaceEnd = Color(0xFF234A40);

  /// Snackbar éxito (verde profesional).
  static const Color success = Color(0xFF2E9B68);

  /// Snackbar error (rojo oscuro, distinto del acento melocotón).
  static const Color error = Color(0xFFB84A4A);

  /// Texto sobre snackbars de feedback.
  static const Color onSnackBar = Color(0xFFFDFDFD);

  /// Enlaces y detalles.
  static const Color accentSky = Color(0xFF7EB6FF);

  /// Superficie ligeramente elevada (listas, hover).
  static const Color surfaceHighlight = Color(0xFF2E3F47);

  /// Relleno de campos de texto (oscuro, legible con texto claro).
  static const Color inputFill = surfaceHighlight;

  /// Texto principal (Off-White).
  static const Color textPrimary = Color(0xFFFDFDFD);

  /// Texto secundario (gris tenue).
  static const Color textSecondary = Color(0xFFA9B7C0);

  /// Texto sobre superficie sand (mejor legibilidad).
  static const Color onSurfaceSecondary = Color(0xFF1A2F35);

  static const double radiusSm = 12;
  static const double radiusMd = 16;

  static const EdgeInsets paddingSm = EdgeInsets.all(8);
  static const EdgeInsets paddingMd = EdgeInsets.all(16);
  static const EdgeInsets paddingLg = EdgeInsets.all(24);
  static const EdgeInsets paddingXl = EdgeInsets.all(32);

  static Color questionTypeAccent(String code) => switch (code) {
        'multiple_choice' => accentViolet,
        'true_false' => accentSky,
        'image_choice' => accentGold,
        'image_based_question' => accentCool,
        _ => accent,
      };

  /// Acento exclusivo del módulo Profesor (indigo-violeta premium).
  static const Color teacherAccent = Color(0xFF7C6FFF);

  /// Superficie del módulo Profesor (glassmorphism suave).
  static const Color teacherAccentSurface = Color(0xFF282050);

  /// Color de advertencia / insight warning.
  static const Color warning = Color(0xFFFFB347);

  static Color publicationStatusColor(String status) => switch (status) {
        'published' => accentMint,
        'draft' => accentGold,
        _ => textSecondary,
      };
}
