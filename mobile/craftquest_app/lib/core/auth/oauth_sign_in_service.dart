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
  String? _configuredGoogleClientId;
  StreamSubscription<GoogleSignInAccount?>? _webUserSubscription;

  bool get isGoogleConfigured => _googleServerClientId.isNotEmpty;

  String get googleServerClientId => _googleServerClientId;

  String get appleWebServicesId => _appleWebServicesId;

  String get appleWebRedirectUri => _appleWebRedirectUri;

  /// Web: Services ID + redirect. Nativo: solo hace falta que la API tenga BundleId.
  bool get isAppleWebConfigured =>
      _appleWebServicesId.isNotEmpty && _appleWebRedirectUri.isNotEmpty;

  GoogleSignIn? get googleSignIn => _googleSignIn;

  void _ensureGoogleSignIn() {
    if (!isGoogleConfigured) {
      return;
    }

    const scopes = ['openid', 'email', 'profile'];

    // Reutilizar la misma instancia en web: renderButton (GIS) notifica vía onCurrentUserChanged.
    if (kIsWeb) {
      if (_googleSignIn == null ||
          _configuredGoogleClientId != _googleServerClientId) {
        _googleSignIn = GoogleSignIn(
          clientId: _googleServerClientId,
          scopes: scopes,
        );
        _configuredGoogleClientId = _googleServerClientId;
      }
      return;
    }

    _googleSignIn ??= GoogleSignIn(
      serverClientId: _googleServerClientId,
      scopes: scopes,
    );
  }

  /// Web: escucha credenciales del botón GIS (`renderButton`). No usar signIn().
  ///
  /// No llama a [GoogleSignIn.signInSilently]: eso dispara One Tap / FedCM al cargar
  /// la pantalla y puede iniciar sesión sin que el usuario pulse el botón.
  void configureWebGoogleListener(
    void Function(OAuthSignInResult result) onResult, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    if (!kIsWeb || !isGoogleConfigured) {
      return;
    }

    _ensureGoogleSignIn();
    final google = _googleSignIn!;

    _webUserSubscription?.cancel();
    _webUserSubscription = google.onCurrentUserChanged.listen(
      (account) async {
        if (account == null) {
          return;
        }
        try {
          final credentials = await _credentialsFromAccount(account);
          if (credentials != null) {
            onResult(credentials);
          }
        } catch (error, stackTrace) {
          onError?.call(error, stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        onError?.call(error, stackTrace);
      },
    );
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
      // En web el idToken llega solo vía renderButton + onCurrentUserChanged.
      return null;
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
