import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';

String resolveTeacherInsightMessage(
  AppLocalizations l10n,
  TeacherInsightModel insight,
) {
  if (insight.message != null && insight.message!.isNotEmpty) {
    return insight.message!;
  }

  final params = insight.params ?? {};
  switch (insight.type) {
    case 'high_error_rate':
      return l10n.teacherInsightHighError(
        params['errorRate'] ?? '0',
        params['questionText'] ?? '',
      );
    case 'most_active_sessions':
      final sessionCount = int.tryParse(params['sessionCount'] ?? '') ?? 0;
      final studentCount = int.tryParse(params['studentCount'] ?? '') ?? 0;
      return l10n.teacherInsightMostActive(
        sessionCount,
        studentCount,
        insight.quizTitle ?? '',
      );
    default:
      return insight.quizTitle ?? '';
  }
}
