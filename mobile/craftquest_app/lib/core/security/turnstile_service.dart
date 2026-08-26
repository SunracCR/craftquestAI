abstract class TurnstileService {
  void configure(String? siteKey);

  Future<String?> requestToken({Duration timeout = const Duration(seconds: 10)});

  bool get isConfigured;
}
