/// URLs legales públicas de CraftQuestAI.
abstract final class LegalUrls {
  static const String baseUrl = 'https://craftquestai.com';

  /// URL canónica en español (metadatos App Store, fallback).
  static const privacyPolicyUrl = '$baseUrl/privacidad';
  static const termsOfServiceUrl = '$baseUrl/terminos';

  static String privacyPolicyUrlFor(String languageCode) =>
      '$baseUrl${_localePrefix(languageCode)}/privacidad';

  static String termsOfServiceUrlFor(String languageCode) =>
      '$baseUrl${_localePrefix(languageCode)}/terminos';

  static String _localePrefix(String languageCode) {
    final code = languageCode.split('_').first.toLowerCase();
    return switch (code) {
      'en' => '/en',
      'pt' => '/pt',
      _ => '',
    };
  }
}
