abstract final class EmailUtils {
  static final RegExp _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValid(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 254) {
      return false;
    }
    return _pattern.hasMatch(trimmed);
  }
}
