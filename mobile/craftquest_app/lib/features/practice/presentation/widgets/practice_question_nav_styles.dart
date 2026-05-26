import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_question_nav_status.dart';
import 'package:flutter/material.dart';

/// Estilos de navegación: relleno por estado de respuesta, borde azul = pregunta actual.
abstract final class PracticeQuestionNavStyles {
  static const Color currentBorder = AppColors.accentCool;
  static const double currentBorderWidth = 2;

  static Color segmentFill(PracticeQuestionNavStatus status) =>
      switch (status) {
        PracticeQuestionNavStatus.answered => AppColors.accentMint,
        PracticeQuestionNavStatus.pending => AppColors.surfaceHighlight,
      };

  static BorderSide? currentOutline(bool isCurrent) => isCurrent
      ? const BorderSide(color: currentBorder, width: currentBorderWidth)
      : null;
}
