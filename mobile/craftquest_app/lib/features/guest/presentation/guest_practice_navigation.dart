import 'package:craftquest_app/features/guest/presentation/bloc/guest_session_cubit.dart';
import 'package:craftquest_app/features/guest/presentation/guest_practice_session_page.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens guest practice immediately so loading feedback appears on the session screen.
Future<void> openGuestPracticeSession(
  BuildContext context, {
  required String visitId,
  required String token,
  required String quizTitle,
  bool? randomizeQuestions,
  bool showElapsedTimer = false,
  bool enableSoundEffects = true,
  Future<PracticeActiveSessionModel?>? activeSessionPrefetch,
}) async {
  if (!context.mounted) {
    return;
  }

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
          enableSoundEffects: enableSoundEffects,
          activeSessionPrefetch: activeSessionPrefetch,
        ),
      ),
    ),
  );
}
