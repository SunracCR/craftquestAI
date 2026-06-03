import 'dart:async';

import 'package:craftquest_app/core/auth/oauth_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuthSignInResult {
  const OAuthSignInResult({
    required this.idToken,
    this.email,
    this.displayName,
  });

  final String idToken;
  final String? email;
  final String? displayName;
}

/// Inicio de sesión con Google y Apple (id_token para la API).
class OAuthSignInService {
  OAuthSignInService({
    String? googleServerClientId,
    String? appleWebServicesId,
    String? appleWebRedirectUri,
  })  : _googleServerClientId = googleServerClientId?.trim() ?? '',
        _appleWebServicesId = appleWebServicesId?.trim() ?? '',
        _appleWebRedirectUri = appleWebRedirectUri?.trim() ?? '';

  final String _googleServerClientId;
  final String _appleWebServicesId;
  final String _appleWebRedirectUri;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _webUserSubscription;

  bool get isGoogleConfigured => _googleServerClientId.isNotEmpty;

  /// Web: Services ID + redirect. Nativo: solo hace falta que la API tenga BundleId.
  bool get isAppleWebConfigured =>
      _appleWebServicesId.isNotEmpty && _appleWebRedirectUri.isNotEmpty;

  GoogleSignIn? get googleSignIn => _googleSignIn;

  void _ensureGoogleSignIn() {
    if (!isGoogleConfigured) {
      return;
    }

    const scopes = ['openid', 'email', 'profile'];

    // google_sign_in_web: assert(serverClientId == null). No pasar ese parámetro.
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: _googleServerClientId,
        scopes: scopes,
      );
      return;
    }

    _googleSignIn ??= GoogleSignIn(
      serverClientId: _googleServerClientId,
      scopes: scopes,
    );
  }

  /// Web: escucha credenciales con idToken (renderButton / One Tap). No usar signIn().
  void configureWebGoogleListener(void Function(OAuthSignInResult result) onResult) {
    if (!kIsWeb || !isGoogleConfigured) {
      return;
    }

    _ensureGoogleSignIn();
    final google = _googleSignIn!;

    _webUserSubscription?.cancel();
    _webUserSubscription = google.onCurrentUserChanged.listen((account) async {
      if (account == null) {
        return;
      }
      final credentials = await _credentialsFromAccount(account);
      if (credentials != null) {
        onResult(credentials);
      }
    });

    unawaited(google.signInSilently());
  }

  void dispose() {
    unawaited(_webUserSubscription?.cancel());
    _webUserSubscription = null;
  }

  Future<bool> isAppleAvailable() => SignInWithApple.isAvailable();

  /// Cierra la sesión de Google en el dispositivo (p. ej. tras cerrar sesión en la app).
  static Future<void> clearGoogleSession({String? serverClientId}) async {
    final clientId = (serverClientId ?? OAuthConfig.googleServerClientId).trim();
    if (clientId.isEmpty) {
      return;
    }

    try {
      if (kIsWeb) {
        final google = GoogleSignIn(
          clientId: clientId,
          scopes: const ['openid', 'email', 'profile'],
        );
        await google.signOut();
        return;
      }

      final google = GoogleSignIn(
        serverClientId: clientId,
        scopes: const ['openid', 'email', 'profile'],
      );
      await google.signOut();
    } catch (_) {
      // Best effort: no bloquear logout ni registro.
    }
  }

  Future<OAuthSignInResult?> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    if (!isGoogleConfigured) {
      throw StateError('Google sign-in is not configured.');
    }

    _ensureGoogleSignIn();
    final google = _googleSignIn!;

    if (forceAccountSelection) {
      await google.signOut();
    }

    GoogleSignInAccount? account;
    if (kIsWeb) {
      // signIn() en web solo devuelve accessToken (sin idToken). Usar One Tap / renderButton.
      await google.signInSilently(suppressErrors: false);
      account = google.currentUser;
    } else {
      account = await google.signIn();
    }

    if (account == null) {
      return null;
    }

    return _credentialsFromAccount(account);
  }

  Future<OAuthSignInResult?> _credentialsFromAccount(
    GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      if (kIsWeb) {
        throw StateError(
          'Google did not return an id token on web. Use the Google sign-in button.',
        );
      }
      throw StateError('Google did not return an id token.');
    }

    return OAuthSignInResult(
      idToken: idToken,
      email: account.email,
      displayName: account.displayName,
    );
  }

  Future<OAuthSignInResult?> signInWithApple() async {
    if (kIsWeb && !isAppleWebConfigured) {
      throw StateError('Apple web sign-in is not configured.');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: kIsWeb
          ? WebAuthenticationOptions(
              clientId: _appleWebServicesId,
              redirectUri: Uri.parse(_appleWebRedirectUri),
            )
          : null,
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple did not return an identity token.');
    }

    final given = credential.givenName;
    final family = credential.familyName;
    final displayName = given == null && family == null
        ? null
        : [given, family].where((p) => p != null && p.isNotEmpty).join(' ');

    return OAuthSignInResult(
      idToken: idToken,
      email: credential.email,
      displayName:
          displayName == null || displayName.isEmpty ? null : displayName,
    );
  }
}
