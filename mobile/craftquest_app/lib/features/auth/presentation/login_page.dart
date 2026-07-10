import 'package:craftquest_app/core/compliance/birth_date_correction.dart';
import 'package:craftquest_app/core/compliance/legal_links.dart';
import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/verify_email_pending_page.dart';
import 'package:craftquest_app/features/auth/presentation/forgot_password_page.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/oauth_sign_in_buttons.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_language_selector.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_header.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/guest_practice_promo_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentialsStorage = getIt<SavedLoginCredentialsStorage>();

  bool _rememberLogin = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSavedCredentials() async {
    try {
      final savedEmail = await _credentialsStorage.readEmail();
      if (!mounted) return;

      if (savedEmail != null) {
        _emailController.text = savedEmail;
        _rememberLogin = true;
      }
    } catch (_) {
      // Sin email guardado o almacenamiento no disponible.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final bloc = context.read<AuthBloc>();
    final loginAttemptId = DateTime.now().millisecondsSinceEpoch;
    final resultFuture = bloc.stream.firstWhere(
      (state) =>
          state is AuthAuthenticated ||
          (state is AuthFailure && state.attemptId == loginAttemptId),
    );
    bloc.add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberCredentials: _rememberLogin,
        attemptId: loginAttemptId,
      ),
    );

    final result = await resultFuture;

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result is AuthFailure) {
      if (result.errorCode == 'EMAIL_NOT_VERIFIED') {
        await _showEmailNotVerifiedDialog(_emailController.text.trim());
      } else {
        context.showErrorSnackBar(result.message);
      }
    }
  }

  Future<void> _showEmailNotVerifiedDialog(String email) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = getIt<AuthRepository>();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.errorEmailNotVerifiedTitle),
        content: Text(l10n.errorEmailNotVerifiedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await repository.resendVerification(email: email);
                if (!mounted) {
                  return;
                }
                context.showSuccessSnackBar(l10n.verifyEmailResentMessage);
              } on DioException catch (e) {
                if (!mounted) {
                  return;
                }
                context.showErrorSnackBar(repository.mapError(e));
              }
            },
            child: Text(l10n.verifyEmailResendAction),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VerifyEmailPendingPage(email: email),
                ),
              );
            },
            child: Text(l10n.verifyEmailPendingTitle),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: Icon(icon, size: 22, color: AppColors.textSecondary),
      suffixIcon: suffix,
    );
  }

  static const double _loginLogoSize = 168;
  static const double _loginMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AuthPremiumBackground(
        child: SafeArea(
          child: Stack(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = _isSubmitting;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final viewInsets = MediaQuery.viewInsetsOf(context);
                      const horizontalPadding = AppSpacing.md;
                      final maxFormWidth = _loginMaxWidth.clamp(
                        0.0,
                        constraints.maxWidth - horizontalPadding * 2,
                      );

                      final form = Form(
                        key: _formKey,
                        child: AuthPremiumCard(
                          dense: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthPremiumHeader(
                                dense: true,
                                logoSize: _loginLogoSize,
                                title: l10n.loginTitle,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AutofillGroup(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      enabled: !isLoading,
                                      textInputAction: TextInputAction.next,
                                      decoration: _fieldDecoration(
                                        label: l10n.emailLabel,
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return l10n.fieldRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      enabled: !isLoading,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: _fieldDecoration(
                                        label: l10n.passwordLabel,
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 22,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.length < 8) {
                                          return l10n.passwordMinLength;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const ForgotPasswordPage(),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    l10n.forgotPasswordLink,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.accent),
                                  ),
                                ),
                              ),
                              _RememberCredentialsTile(
                                value: _rememberLogin,
                                label: l10n.loginRememberCredentials,
                                enabled: !isLoading,
                                onChanged: (value) {
                                  setState(() => _rememberLogin = value);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppGradientPrimaryButton(
                                label: l10n.loginAction,
                                icon: Icons.login_rounded,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OAuthSignInButtons(enabled: !isLoading),
                              const SizedBox(height: AppSpacing.sm),
                              Divider(
                                height: 1,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Center(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          final authBloc =
                                              context.read<AuthBloc>();
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                value: authBloc,
                                                child: const RegisterPage(),
                                              ),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    l10n.goToRegister,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Divider(
                                height: 1,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.15),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const GuestPracticePromoCard(compact: true),
                              const LegalLinksRow(),
                              Center(
                                child: TextButton(
                                  onPressed: () async {
                                    await BirthDateCorrection
                                        .requestFullAgeScreen();
                                  },
                                  child: Text(
                                    l10n.correctBirthDateLoginHint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.sm,
                          horizontalPadding,
                          AppSpacing.sm + viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight -
                                    AppSpacing.sm * 2 -
                                    viewInsets.bottom)
                                .clamp(0.0, double.infinity),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: maxFormWidth,
                              child: form,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: AuthLanguageSelector(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RememberCredentialsTile extends StatelessWidget {
  const _RememberCredentialsTile({
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                  activeColor: AppColors.accent,
                  checkColor: AppColors.background,
                  side: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
