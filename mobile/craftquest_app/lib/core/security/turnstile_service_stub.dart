import 'package:craftquest_app/core/security/turnstile_service.dart';

TurnstileService createTurnstileService() => _TurnstileServiceStub();

class _TurnstileServiceStub implements TurnstileService {
  @override
  void configure(String? siteKey) {}

  @override
  bool get isConfigured => false;

  @override
  Future<String?> requestToken({Duration timeout = const Duration(seconds: 10)}) async {
    return null;
  }
}
