import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/features/practice/presentation/practice_session_page.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_resume_dialog.dart';
import 'package:flutter/material.dart';

Future<void> openPracticeSession(
  BuildContext context, {
  required String quizId,
  required String quizTitle,
  String? resumeSessionId,
  String? classId,
  String? assignmentId,
}) async {
  final practiceRepository = getIt<PracticeRepository>();
  final preferencesRepository = getIt<PracticePreferencesRepository>();

  String? sessionToResume = resumeSessionId;
  var options = PracticeLaunchOptions.defaults;

  if (sessionToResume == null) {
    try {
      final active = await practiceRepository.getActiveSessionForQuiz(
        quizId,
        assignmentId: assignmentId,
      );
      if (!context.mounted) return;

      if (active != null) {
        final choice = await showPracticeResumeDialog(
          context,
          summary: active,
        );
        if (!context.mounted || choice == null || choice == PracticeResumeChoice.cancel) {
          return;
        }
        if (choice == PracticeResumeChoice.resume) {
          sessionToResume = active.practiceSessionId;
        } else if (choice == PracticeResumeChoice.startNew) {
          await practiceRepository.abandonSession(active.practiceSessionId);
        }
      }
    } catch (_) {
      // Continue with a new session if active lookup fails.
    }
  }

  if (sessionToResume == null) {
    try {
      options = await preferencesRepository.loadLaunchOptions(quizId);
    } catch (_) {
      // Keep defaults if preferences cannot be loaded.
    }
  }

  if (!context.mounted) {
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PracticeSessionPage(
        quizId: quizId,
        quizTitle: quizTitle,
        options: options,
        resumeSessionId: sessionToResume,
        classId: classId,
        assignmentId: assignmentId,
      ),
    ),
  );
}
