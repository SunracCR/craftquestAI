import 'package:shared_preferences/shared_preferences.dart';

/// Límite local de canjes de código como invitado (por dispositivo, reinicio diario).
abstract final class AnonymousPracticeLimitStore {
  static const maxRedemptions = 3;
  static const _countKey = 'anonymous_practice_count';
  static const _dayKey = 'anonymous_practice_day';

  static String _calendarDayKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _todayKey() => _calendarDayKey(DateTime.now());

  static Future<int> _countForToday(SharedPreferences prefs) async {
    final today = _todayKey();
    final storedDay = prefs.getString(_dayKey);
    if (storedDay != today) {
      return 0;
    }
    return prefs.getInt(_countKey) ?? 0;
  }

  static Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _countForToday(prefs);
  }

  static Future<bool> canRedeemCode() async =>
      (await getCount()) < maxRedemptions;

  static Future<void> recordSuccessfulRedemption() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final current = await _countForToday(prefs);
    final next = current + 1;
    await prefs.setString(_dayKey, today);
    await prefs.setInt(_countKey, next);
  }
}
