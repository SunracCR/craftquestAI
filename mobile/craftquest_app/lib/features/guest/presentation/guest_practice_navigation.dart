import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_practice_session_page.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_resume_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> openGuestPracticeSession(
  BuildContext context, {
  required String visitId,
  required String token,
  required String quizTitle,
  bool? randomizeQuestions,
  bool showElapsedTimer = false,
}) async {
  final repository = getIt<GuestRepository>();
  String? sessionToResume;

  try {
    final active = await repository.getActiveSession(
      visitId: visitId,
      token: token,
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
        await repository.abandonSession(
          visitId: visitId,
          token: token,
          sessionId: active.practiceSessionId,
        );
      }
    }
  } catch (_) {
    // Continue with a new session if active lookup fails.
  }

  if (!context.mounted) return;

  final guestCubit = context.read<GuestSessionCubit>();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: guestCubit,
        child: GuestPracticeSessionPage(
          visitId: visitId,
          token: token,
          quizTitle: quizTitle,
          randomizeQuestions: randomizeQuestions,
          showElapsedTimer: showElapsedTimer,
          resumeSessionId: sessionToResume,
        ),
      ),
    ),
  );
}
