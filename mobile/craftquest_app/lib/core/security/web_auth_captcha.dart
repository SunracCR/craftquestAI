import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/security/turnstile_service.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart';

/// Resolves an invisible Turnstile token for web login/register flows.
Future<String?> requestWebAuthCaptchaToken() async {
  if (!kIsWeb) {
    return null;
  }

  final turnstile = getIt<TurnstileService>();
  if (!turnstile.isConfigured) {
    try {
      final config = await getIt<AuthRepository>().getOAuthConfig();
      turnstile.configure(config.turnstileSiteKey);
    } catch (_) {
      return null;
    }
  }

  if (!turnstile.isConfigured) {
    return null;
  }

  return turnstile.requestToken();
}
