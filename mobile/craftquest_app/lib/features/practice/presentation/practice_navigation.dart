import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/safe_navigation.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/features/practice/presentation/practice_session_page.dart';
import 'package:flutter/material.dart';

/// Opens the practice session screen immediately so the student sees loading
/// feedback while the app resolves resume/start in [PracticeSessionPage].
Future<bool?> openPracticeSession(
  BuildContext context, {
  required String quizId,
  required String quizTitle,
  String? resumeSessionId,
  String? classId,
  String? assignmentId,
  bool assignmentRandomizeQuestions = false,
  bool allowStudentRandomizeQuestions = false,
  bool forfeitExitCountsAsAttempt = false,
  Future<PracticeActiveSessionModel?>? activeSessionPrefetch,
  Future<PracticeLaunchOptions>? launchOptionsPrefetch,
  bool launchOptionsResolved = false,
  PracticeLaunchOptions? launchOptions,
}) async {
  if (!context.mounted) {
    return null;
  }

  final options = launchOptions ??
      (assignmentId != null
          ? PracticeLaunchOptions(
              randomizeQuestions: assignmentRandomizeQuestions,
              showTimer: PracticeLaunchOptions.defaults.showTimer,
            )
          : PracticeLaunchOptions.defaults);

  if (resumeSessionId == null && options.enableSoundEffects) {
    final soundService = getIt<SoundService>();
    unawaited(soundService.warmUp());
    soundService.playStartSfx();
  }

  return SafeNavigation.pushPage<bool>(
    context,
    PracticeSessionPage(
      quizId: quizId,
      quizTitle: quizTitle,
      options: options,
      resumeSessionId: resumeSessionId,
      classId: classId,
      assignmentId: assignmentId,
      allowAssignmentRandomizeOverride: allowStudentRandomizeQuestions,
      forfeitExitCountsAsAttempt: forfeitExitCountsAsAttempt,
      activeSessionPrefetch: activeSessionPrefetch,
      launchOptionsPrefetch: launchOptionsPrefetch,
      launchOptionsResolved: launchOptionsResolved,
    ),
  );
}
