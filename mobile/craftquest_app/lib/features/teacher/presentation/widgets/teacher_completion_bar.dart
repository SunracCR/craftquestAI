import 'package:flutter/material.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';

class TeacherCompletionBar extends StatelessWidget {
  const TeacherCompletionBar({
    super.key,
    required this.completedCount,
    required this.totalMembers,
    this.label,
    this.color,
    this.height = 8,
  });

  final int completedCount;
  final int totalMembers;
  final String? label;
  final Color? color;
  final double height;

  double get _ratio =>
      totalMembers > 0 ? (completedCount / totalMembers).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.teacherAccent;
    final pct = (_ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Flexible(
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              '$completedCount / $totalMembers ($pct%)',
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: _ratio,
            minHeight: height,
            backgroundColor: barColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
