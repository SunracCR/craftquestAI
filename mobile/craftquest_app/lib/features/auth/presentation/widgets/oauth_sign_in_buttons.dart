import 'dart:async';

import 'package:craftquest_app/core/auth/oauth_config.dart';
import 'package:craftquest_app/core/auth/oauth_sign_in_service.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/oauth_brand_logos.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/oauth_google_web_button.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Botones premium de inicio de sesión con Google y Apple.
class OAuthSignInButtons extends StatefulWidget {
  const OAuthSignInButtons({
    super.key,
    this.enabled = true,
    this.forceGoogleAccountSelection = false,
  });

  final bool enabled;

  /// En registro: evita reutilizar la cuenta Google del último login sin preguntar.
  final bool forceGoogleAccountSelection;

  @override
  State<OAuthSignInButtons> createState() => _OAuthSignInButtonsState();
}

class _OAuthSignInButtonsState extends State<OAuthSignInButtons> {
  OAuthSignInService? _oauth;
  AuthBloc? _authBloc;
  StreamSubscription<AuthState>? _authSubscription;
  bool _appleAvailable = false;
  bool _busy = false;
  bool _apiAppleConfigured = false;
  int _signInGeneration = 0;
  String? _lastSubmittedOAuthIdToken;

  static bool get _supportsGoogleUi =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  static bool get _supportsAppleUi =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _initOAuthFromLocal();
    unawaited(_refreshOAuthConfigFromApi());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<AuthBloc>();
    if (!identical(_authBloc, bloc)) {
      unawaited(_authSubscription?.cancel());
      _authBloc = bloc;
      _authSubscription = bloc.stream.listen(_onAuthStateChanged);
    }
  }

  void _onAuthStateChanged(AuthState state) {
    if (!mounted) {
      return;
    }
    if (state is AuthAuthenticated || state is AuthFailure) {
      setState(() => _busy = false);
    }
    if (state is AuthAuthenticated) {
      _lastSubmittedOAuthIdToken = null;
      return;
    }
    if (state is AuthFailure) {
      _lastSubmittedOAuthIdToken = null;
      unawaited(_maybeShowOAuthFailure(state.message));
    }
  }

  Future<void> _maybeShowOAuthFailure(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) {
      return;
    }
    if (_authBloc?.state is AuthAuthenticated) {
      return;
    }
    AppSnackBars.showError(message);
  }

  @override
  void dispose() {
    _signInGeneration++;
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    _oauth?.dispose();
    super.dispose();
  }

  void _initOAuthFromLocal({
    String? googleClientId,
    String? appleServicesId,
    String? appleWebRedirectUri,
  }) {
    final resolvedGoogleClientId =
        googleClientId ?? OAuthConfig.googleServerClientId;
    var resolvedAppleRedirect = appleWebRedirectUri;
    if (kIsWeb &&
        (resolvedAppleRedirect == null || resolvedAppleRedirect.isEmpty)) {
      resolvedAppleRedirect = '${Uri.base.origin}/';
      if (!resolvedAppleRedirect.endsWith('/')) {
        resolvedAppleRedirect = '$resolvedAppleRedirect/';
      }
    }

    final oauth = _oauth;
    final reuseOAuth = oauth != null &&
        oauth.googleServerClientId == resolvedGoogleClientId &&
        oauth.appleWebServicesId == (appleServicesId ?? '') &&
        oauth.appleWebRedirectUri == (resolvedAppleRedirect ?? '');

    if (reuseOAuth) {
      if (kIsWeb && resolvedGoogleClientId.isNotEmpty) {
        oauth.configureWebGoogleListener(
          _onWebGoogleCredentials,
          onError: _onWebGoogleError,
        );
      }
      return;
    }

    final newOAuth = OAuthSignInService(
      googleServerClientId: resolvedGoogleClientId,
      appleWebServicesId: appleServicesId,
      appleWebRedirectUri: resolvedAppleRedirect,
    );
    if (kIsWeb && resolvedGoogleClientId.isNotEmpty) {
      newOAuth.configureWebGoogleListener(
        _onWebGoogleCredentials,
        onError: _onWebGoogleError,
      );
    }

    _oauth?.dispose();
    _oauth = newOAuth;
  }

  void _onWebGoogleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('OAuth web Google listener error: $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    _lastSubmittedOAuthIdToken = null;
    final l10n = AppLocalizations.of(context)!;
    final detail = error.toString();
    final hint = _oauthFailureHint(
      error: error,
      detail: detail,
      provider: 'google',
      l10n: l10n,
    );
    AppSnackBars.showError('${l10n.oauthSignInFailed}$hint');
  }

  Future<void> _refreshOAuthConfigFromApi() async {
    var googleClientId = OAuthConfig.googleServerClientId;
    String? appleServicesId;
    String? appleWebRedirectUri;

    try {
      final remote = await getIt<AuthRepository>().getOAuthConfig();
      _apiAppleConfigured = remote.isAppleConfigured;
      appleServicesId = remote.appleServicesId;
      appleWebRedirectUri = remote.appleWebRedirectUri;
      if (remote.googleWebClientId != null &&
          remote.googleWebClientId!.isNotEmpty) {
        googleClientId = remote.googleWebClientId!;
      }
    } catch (_) {
      // API no disponible: mantener IDs locales.
    }

    if (kIsWeb &&
        (appleWebRedirectUri == null || appleWebRedirectUri.isEmpty)) {
      appleWebRedirectUri = '${Uri.base.origin}/';
      if (!appleWebRedirectUri.endsWith('/')) {
        appleWebRedirectUri = '$appleWebRedirectUri/';
      }
    }

    var appleAvailable = _appleAvailable;
    if (_supportsAppleUi) {
      try {
        appleAvailable = await SignInWithApple.isAvailable();
      } catch (_) {
        appleAvailable = false;
      }
    }

    if (!mounted) return;

    _initOAuthFromLocal(
      googleClientId: googleClientId,
      appleServicesId: appleServicesId,
      appleWebRedirectUri: appleWebRedirectUri,
    );

    setState(() {
      _appleAvailable = kIsWeb ? true : appleAvailable;
    });
  }

  void _onWebGoogleCredentials(OAuthSignInResult credentials) {
    if (!mounted || !widget.enabled) {
      return;
    }
    if (_busy) {
      return;
    }
    if (_lastSubmittedOAuthIdToken == credentials.idToken) {
      return;
    }
    _lastSubmittedOAuthIdToken = credentials.idToken;
    unawaited(
      _signIn(
        obtainCredentials: () async => credentials,
        provider: 'google',
      ),
    );
  }

  bool get _showGoogle => _supportsGoogleUi;

  bool get _showApple => _supportsAppleUi;

  Future<void> _signInGoogle() async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final oauth = _oauth;
    if (oauth == null || !oauth.isGoogleConfigured) {
      AppSnackBars.showError(l10n.oauthGoogleNotConfigured);
      return;
    }
    await _signIn(
      obtainCredentials: () => oauth.signInWithGoogle(
        forceAccountSelection: widget.forceGoogleAccountSelection,
      ),
      provider: 'google',
    );
  }

  Widget _buildGoogleSignInButton({
    required String label,
    required bool compactInline,
    required double logoSize,
  }) {
    final height = compactInline ? 44.0 : AppSpacing.buttonHeight - 4;
    final radius = compactInline ? 12.0 : 14.0;

    final premiumButton = _PremiumOAuthButton(
      label: label,
      enabled: widget.enabled && !_busy,
      compactInline: compactInline,
      backgroundColor: AppColors.surfaceHighlight,
      foregroundColor: AppColors.textPrimary,
      borderColor: AppColors.inputBorder.withValues(alpha: 0.55),
      highlightColor: AppColors.accentCool.withValues(alpha: 0.12),
      logo: GoogleBrandLogo(size: logoSize),
      // En web el clic lo recibe el botón GIS debajo (overlay decorativo).
      onPressed: kIsWeb ? () {} : _signInGoogle,
    );

    final button = buildOAuthGoogleWebButton(
      overlay: premiumButton,
      height: height,
      borderRadius: radius,
    );

    if (!widget.enabled || _busy) {
      return AbsorbPointer(child: button);
    }
    return button;
  }

  Future<void> _signInApple() async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_appleAvailable) {
      AppSnackBars.showError(l10n.oauthAppleNotAvailable);
      return;
    }
    if (!kIsWeb && !_apiAppleConfigured) {
      AppSnackBars.showError(l10n.oauthAppleNotConfigured);
      return;
    }
    final oauth = _oauth;
    if (oauth == null) return;
    if (kIsWeb && !oauth.isAppleWebConfigured) {
      AppSnackBars.showError(l10n.oauthAppleWebNotConfigured);
      return;
    }
    await _signIn(
      obtainCredentials: oauth.signInWithApple,
      provider: 'apple',
    );
  }

  Future<void> _signIn({
    required Future<OAuthSignInResult?> Function() obtainCredentials,
    required String provider,
  }) async {
    if (!widget.enabled || _busy || !context.mounted) return;

    final bloc = _authBloc;
    if (bloc == null) return;

    final generation = ++_signInGeneration;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _busy = true);

    try {
      final credentials = await obtainCredentials();
      if (!context.mounted || generation != _signInGeneration) return;
      if (credentials == null) {
        setState(() => _busy = false);
        return;
      }

      // Iniciar sesión (o vincular cuenta existente); _AuthGate navega al éxito.
      bloc.add(
        AuthOAuthSignInRequested(
          provider: provider,
          idToken: credentials.idToken,
          email: credentials.email,
          displayName: credentials.displayName,
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('OAuth sign-in error ($provider): $e');
        debugPrint('$stackTrace');
      }
      if (!context.mounted || generation != _signInGeneration) return;
      setState(() => _busy = false);
      final detail = e.toString();
      final hint = _oauthFailureHint(
        error: e,
        detail: detail,
        provider: provider,
        l10n: l10n,
      );
      final message = kDebugMode && detail.isNotEmpty
          ? '${l10n.oauthSignInFailed}$hint\n$detail'
          : '${l10n.oauthSignInFailed}$hint';
      AppSnackBars.showError(message);
    }
  }

  static String _oauthFailureHint({
    required Object error,
    required String detail,
    required String provider,
    required AppLocalizations l10n,
  }) {
    if (provider == 'google' &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      if (error is PlatformException) {
        final message = error.message ?? '';
        if (error.code == 'sign_in_failed' &&
            (message.contains('10') ||
                message.toUpperCase().contains('DEVELOPER_ERROR'))) {
          return l10n.oauthGoogleAndroidSigningHint;
        }
      }
      if (detail.contains('id token') || detail.contains('id_token')) {
        return l10n.oauthGoogleAndroidSigningHint;
      }
    }

    if (detail.contains('people.googleapis.com') ||
        detail.contains('People API') ||
        detail.contains('SERVICE_DISABLED')) {
      return l10n.oauthGooglePeopleApiHint;
    }
    if (kIsWeb &&
        (detail.contains('origin') ||
            detail.contains('Origin') ||
            detail.contains('popup') ||
            detail.contains('FedCM'))) {
      return l10n.oauthGoogleWebOriginHint;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGoogle && !_showApple) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = _showGoogle && _showApple;
        final narrow = constraints.maxWidth < 340;
        final googleLabel = sideBySide || narrow
            ? l10n.oauthSignInGoogleShort
            : l10n.oauthSignInWithGoogle;
        final appleLabel = sideBySide || narrow
            ? l10n.oauthSignInAppleShort
            : l10n.oauthSignInWithApple;
        const logoSize = 20.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OAuthDivider(label: l10n.oauthDividerLabel),
            const SizedBox(height: AppSpacing.xs),
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGoogleSignInButton(
                      label: googleLabel,
                      compactInline: true,
                      logoSize: logoSize,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _PremiumOAuthButton(
                      label: appleLabel,
                      enabled: widget.enabled && !_busy,
                      compactInline: true,
                      backgroundColor: const Color(0xFFFDFDFD),
                      foregroundColor: const Color(0xFF1A1A1A),
                      borderColor: Colors.white.withValues(alpha: 0.12),
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                      logo: const AppleBrandLogo(
                        size: logoSize,
                        color: Color(0xFF1A1A1A),
                      ),
                      onPressed: _signInApple,
                    ),
                  ),
                ],
              )
            else ...[
              if (_showGoogle)
                _buildGoogleSignInButton(
                  label: googleLabel,
                  compactInline: false,
                  logoSize: 22,
                ),
              if (_showApple) ...[
                if (_showGoogle) const SizedBox(height: AppSpacing.xs),
                _PremiumOAuthButton(
                  label: appleLabel,
                  enabled: widget.enabled && !_busy,
                  backgroundColor: const Color(0xFFFDFDFD),
                  foregroundColor: const Color(0xFF1A1A1A),
                  borderColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  logo: const AppleBrandLogo(
                    size: 22,
                    color: Color(0xFF1A1A1A),
                  ),
                  onPressed: _signInApple,
                ),
              ],
            ],
            if (_busy) ...[
              const SizedBox(height: AppSpacing.xs),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OAuthDivider extends StatelessWidget {
  const _OAuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.28),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.28),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _PremiumOAuthButton extends StatefulWidget {
  const _PremiumOAuthButton({
    required this.label,
    required this.logo,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.highlightColor,
    required this.enabled,
    this.compactInline = false,
  });

  final String label;
  final Widget logo;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color highlightColor;
  final bool enabled;

  /// Botón en fila (50 % ancho): más bajo y contenido centrado.
  final bool compactInline;

  @override
  State<_PremiumOAuthButton> createState() => _PremiumOAuthButtonState();
}

class _PremiumOAuthButtonState extends State<_PremiumOAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled;
    final height = widget.compactInline ? 44.0 : AppSpacing.buttonHeight - 4;
    final radius = widget.compactInline ? 12.0 : 14.0;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: canTap,
      child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canTap ? widget.onPressed : null,
              onHighlightChanged: canTap
                  ? (value) => setState(() => _pressed = value)
                  : null,
              borderRadius: BorderRadius.circular(radius),
              splashColor: widget.highlightColor,
              highlightColor: widget.highlightColor,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: widget.backgroundColor,
                  border: Border.all(color: widget.borderColor, width: 1),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: widget.compactInline ? 6 : 10,
                            offset: Offset(0, widget.compactInline ? 2 : 4),
                          ),
                        ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compactInline ? 10 : AppSpacing.md,
                  ),
                  child: widget.compactInline
                      ? Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widget.logo,
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: widget.foregroundColor,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.05,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            widget.logo,
                            Expanded(
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: widget.foregroundColor,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 22),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
