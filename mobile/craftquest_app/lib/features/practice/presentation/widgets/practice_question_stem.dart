import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Enunciado de pregunta en sesión de práctica: justificado y legible en textos largos.
class PracticeQuestionStem extends StatelessWidget {
  const PracticeQuestionStem({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: baseStyle?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
