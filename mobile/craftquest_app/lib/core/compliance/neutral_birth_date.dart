/// Fecha de nacimiento escrita por el usuario, sin valor preseleccionado.
abstract final class NeutralBirthDate {
  static const maxAgeYears = 100;

  static bool isComplete({
    required String dayText,
    required String yearText,
    required int? month,
  }) {
    return dayText.trim().isNotEmpty &&
        yearText.trim().length == 4 &&
        month != null;
  }

  /// Devuelve la fecha solo si día, mes y año forman una fecha real,
  /// no futura y no anterior a [maxAgeYears].
  static DateTime? parse({
    required String dayText,
    required String yearText,
    required int? month,
    DateTime? today,
  }) {
    if (!isComplete(dayText: dayText, yearText: yearText, month: month)) {
      return null;
    }

    final day = int.tryParse(dayText.trim());
    final year = int.tryParse(yearText.trim());
    if (day == null || year == null || month == null) {
      return null;
    }

    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final oldest = DateTime(now.year - maxAgeYears, now.month, now.day);
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    if (year < oldest.year || year > todayDate.year) {
      return null;
    }

    final date = DateTime(year, month, day);
    final isRealDate =
        date.year == year && date.month == month && date.day == day;
    if (!isRealDate || date.isAfter(todayDate) || date.isBefore(oldest)) {
      return null;
    }
    return date;
  }
}
