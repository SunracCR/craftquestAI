import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_hub_page.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/features/sharing/presentation/accessible_quizzes_page.dart';
import 'package:craftquest_app/features/student/presentation/student_assignments_page.dart';
import 'package:flutter/material.dart';

/// Navega al destino indicado por el payload de una notificación.
class NotificationNavigation {
  static Future<void> open(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final data = notification.data;
    final route = data?.route;

    if (route != null && route.isNotEmpty) {
      if (route.startsWith('student/assignments/')) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const StudentAssignmentsPage(),
          ),
        );
        return;
      }

      if (route.startsWith('quizzes/')) {
        final quizId = route.split('/').last;
        if (quizId.isNotEmpty) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => QuizDetailPage(quizId: quizId),
            ),
          );
          return;
        }
      }

      if (route == 'profile/billing') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const UpgradePlanPage(),
          ),
        );
        return;
      }

      if (route == 'ai/jobs') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AiGenerationHubPage(),
          ),
        );
        return;
      }
    }

    switch (notification.type) {
      case 'quiz_shared':
        if (data?.quizId != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => QuizDetailPage(quizId: data!.quizId!),
            ),
          );
        } else {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const AccessibleQuizzesPage(),
            ),
          );
        }
      case 'class_joined':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const StudentAssignmentsPage(),
          ),
        );
      case 'assignment_created':
      case 'assignment_due_soon':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const StudentAssignmentsPage(),
          ),
        );
      case 'ai_job_completed':
      case 'ai_job_failed':
        if (data?.quizId != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => QuizDetailPage(quizId: data!.quizId!),
            ),
          );
        } else {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const AiGenerationHubPage(),
            ),
          );
        }
      case 'membership_expiring':
      case 'membership_expired':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const UpgradePlanPage(),
          ),
        );
      default:
        break;
    }
  }
}
