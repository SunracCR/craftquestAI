import 'package:flutter/foundation.dart';

/// OAuth client IDs: API (`GET /api/auth/oauth-config`) o `--dart-define=GOOGLE_SERVER_CLIENT_ID`.
abstract final class OAuthConfig {
  /// Mismo Web Client ID que `ExternalAuth:Google:WebClientId` en la API.
  static const _defaultGoogleWebClientId =
      '398143602966-d4urqebho1niu1qt7lgmqgvc2gn52c35.apps.googleusercontent.com';

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: _defaultGoogleWebClientId,
  );

  static bool get isGoogleEnabled => googleServerClientId.isNotEmpty;

  static bool get isAppleNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Google: Android nativo (+ Windows) y web. No en iOS/macOS.
  static bool get showGoogleSignInButton =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.windows;

  /// Apple: iOS/macOS nativo y web. No en Android.
  static bool get showAppleSignInButton =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
