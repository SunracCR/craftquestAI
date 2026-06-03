/// Utilidades para mostrar banderas por código ISO 3166-1 alpha-2 (p. ej. CR, US).
abstract final class CountryFlagUtils {
  static String? imageUrl(String? countryCode, {int width = 160}) {
    final code = countryCode?.trim().toUpperCase();
    if (code == null || code.length != 2) {
      return null;
    }
    return 'https://flagcdn.com/w$width/${code.toLowerCase()}.png';
  }

  static String emoji(String? countryCode) {
    final code = countryCode?.trim().toUpperCase();
    if (code == null || code.length != 2) {
      return '🏳️';
    }
    final first = code.codeUnitAt(0);
    final second = code.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) {
      return '🏳️';
    }
    return String.fromCharCodes([
      0x1F1E6 + (first - 65),
      0x1F1E6 + (second - 65),
    ]);
  }
}
