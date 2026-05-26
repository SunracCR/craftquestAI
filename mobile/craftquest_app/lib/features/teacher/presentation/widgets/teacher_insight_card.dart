import 'package:flutter/material.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';

class TeacherInsightCard extends StatelessWidget {
  const TeacherInsightCard({
    super.key,
    required this.insight,
    required this.message,
    this.onTap,
  });

  final TeacherInsightModel insight;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWarning = insight.isWarning;
    final color = isWarning ? AppColors.warning : AppColors.accentMint;
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.trending_up_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (insight.quizTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      insight.quizTitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
