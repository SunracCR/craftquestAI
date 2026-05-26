import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatTeacherAttemptDate(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  return DateFormat.yMMMd(locale).add_Hm().format(local);
}

String formatTeacherAttemptDuration(int? seconds) {
  if (seconds == null || seconds <= 0) {
    return '';
  }
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$secs';
  }
  return '$minutes:$secs';
}

String buildTeacherAttemptSubtitle(
  AppLocalizations l10n, {
  required double obtained,
  required double possible,
  required String percent,
  required String status,
  int? durationSeconds,
  required bool showElapsedTimer,
}) {
  final stats = l10n.teacherAttemptSubtitle(
    obtained,
    possible,
    percent,
    status,
  );
  if (!showElapsedTimer || durationSeconds == null || durationSeconds <= 0) {
    return stats;
  }
  return l10n.teacherAttemptSubtitleWithDuration(
    stats,
    formatTeacherAttemptDuration(durationSeconds),
  );
}
