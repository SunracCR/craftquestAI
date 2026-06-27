import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/safe_navigation.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
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
  if (enableSoundEffects) {
    final soundService = getIt<SoundService>();
    unawaited(soundService.warmUp());
    soundService.playStartSfx();
  }

  await SafeNavigation.pushPage<void>(
    context,
    BlocProvider.value(
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
  );
}
