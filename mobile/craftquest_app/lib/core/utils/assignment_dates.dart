import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fechas de asignación como día de calendario (sin desfase por zona horaria).
abstract final class AssignmentDates {
  static DateTime parseFromApi(String iso) => calendarUtc(DateTime.parse(iso));

  static DateTime calendarUtc(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static DateTime todayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Día de calendario almacenado (componentes UTC del API).
  static DateTime calendarDate(DateTime value) {
    final d = calendarUtc(value);
    return DateTime(d.year, d.month, d.day);
  }

  static String toApiIso(DateTime calendarDate) {
    return DateTime.utc(
      calendarDate.year,
      calendarDate.month,
      calendarDate.day,
    ).toIso8601String();
  }

  static String format(BuildContext context, DateTime date) {
    final d = calendarUtc(date);
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));
  }

  static String formatWithLocale(String locale, DateTime date) {
    final d = calendarUtc(date);
    return DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));
  }

  /// Fecha y hora localizadas (p. ej. intentos de invitado).
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale)
        .add_jm()
        .format(dateTime.toLocal());
  }

  /// La asignación aún no abrió (hoy local es anterior al día de inicio).
  static bool isNotYetOpen(DateTime? startsAt) {
    if (startsAt == null) return false;
    return todayLocal().isBefore(calendarDate(startsAt));
  }

  /// La asignación ya venció (hoy local es posterior al día límite).
  static bool isPastDue(DateTime? dueAt) {
    if (dueAt == null) return false;
    return todayLocal().isAfter(calendarDate(dueAt));
  }
}
