import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia del banner «¿Eres docente?» en inicio (por usuario).
///
/// - **free** (y otros no Pro): como mucho una vez por semana ISO; al cerrar,
///   oculto hasta la semana siguiente.
/// - **pro**: como mucho una vez por mes calendario; al cerrar, oculto hasta
///   el mes siguiente.
abstract final class HomeTeacherBannerPrefs {
  static const _legacyDismissedForeverKey = 'teacher_banner_dismissed';
  static const _legacyProShownMonthKey = 'teacher_banner_pro_shown_month';

  static String _freeWeekKey(String userId) =>
      'teacher_banner_free_shown_week_$userId';

  static String _proMonthKey(String userId) =>
      'teacher_banner_pro_shown_month_$userId';

  static String _legacyDismissedForeverUserKey(String userId) =>
      'teacher_banner_dismissed_$userId';

  static bool _isProPlan(String? planCode) =>
      planCode != null && planCode.toLowerCase() == 'pro';

  static String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Semana ISO 8601, p. ej. `2026-W21`.
  static String _isoWeekKey(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final weekday = utc.weekday;
    final thursday = utc.add(Duration(days: 4 - weekday));
    final year = thursday.year;
    final jan4 = DateTime.utc(year, 1, 4);
    final jan4Thursday = jan4.add(Duration(days: 4 - jan4.weekday));
    final week = 1 + thursday.difference(jan4Thursday).inDays ~/ 7;
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  static String _currentPeriodKey(String? planCode) =>
      _isProPlan(planCode)
          ? _monthKey(DateTime.now())
          : _isoWeekKey(DateTime.now());

  static String _storageKey(String userId, String? planCode) =>
      _isProPlan(planCode) ? _proMonthKey(userId) : _freeWeekKey(userId);

  static Future<void> _migrateLegacy(
    SharedPreferences prefs,
    String userId,
  ) async {
    final freeKey = _freeWeekKey(userId);
    if (!prefs.containsKey(freeKey)) {
      final legacyForever = prefs.getBool(_legacyDismissedForeverKey) ??
          prefs.getBool(_legacyDismissedForeverUserKey(userId)) ??
          false;
      if (legacyForever) {
        await prefs.setString(freeKey, _isoWeekKey(DateTime.now()));
      }
    }

    final proKey = _proMonthKey(userId);
    if (!prefs.containsKey(proKey)) {
      final legacyMonth = prefs.getString(_legacyProShownMonthKey);
      if (legacyMonth != null) {
        await prefs.setString(proKey, legacyMonth);
      }
    }
  }

  /// Si el banner debe permanecer oculto en el periodo actual (semana o mes).
  static Future<bool> isHidden({
    required String userId,
    required String? planCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs, userId);

    final stored = prefs.getString(_storageKey(userId, planCode));
    return stored == _currentPeriodKey(planCode);
  }

  /// Marca el periodo actual como «ya visto / cerrado».
  static Future<void> markSuppressedForCurrentPeriod({
    required String userId,
    required String? planCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(userId, planCode),
      _currentPeriodKey(planCode),
    );
  }

  /// Usuario cerró el banner: oculto hasta la siguiente semana o mes.
  ///
  /// Si el plan aún no cargó ([planCode] null), se asume Free (semanal).
  static Future<void> dismiss({
    required String userId,
    required String? planCode,
  }) async {
    await markSuppressedForCurrentPeriod(userId: userId, planCode: planCode);
  }
}
