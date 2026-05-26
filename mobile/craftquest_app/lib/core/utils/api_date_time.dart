/// Parses API date-time strings (stored as UTC) into local [DateTime].
DateTime parseApiUtcDateTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw FormatException('Empty date-time value');
  }

  final hasOffset = trimmed.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(trimmed);

  final parsed = DateTime.parse(hasOffset ? trimmed : '${trimmed}Z');
  return parsed.toLocal();
}

DateTime? tryParseApiUtcDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return parseApiUtcDateTime(value);
}
