import 'package:craftquest_app/core/auth/saved_login_credentials_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_header.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/guest_practice_promo_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
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
  bool _loadingSavedCredentials = true;
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
      final saved = await _credentialsStorage.read();
      if (!mounted) return;

      if (saved != null) {
        _emailController.text = saved.email;
        _passwordController.text = saved.password;
        _rememberLogin = true;
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSavedCredentials = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final bloc = context.read<AuthBloc>();
    final resultFuture = bloc.stream.firstWhere(
      (state) => state is AuthFailure || state is AuthAuthenticated,
    );
    bloc.add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberCredentials: _rememberLogin,
      ),
    );

    final result = await resultFuture;

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result is AuthFailure) {
      context.showErrorSnackBar(result.message);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: AppColors.textSecondary),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthPremiumBackground(
        child: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = _isSubmitting;

              if (_loadingSavedCredentials) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        Form(
                      key: _formKey,
                      child: AuthPremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthPremiumHeader(
                              title: l10n.loginTitle,
                              subtitle: l10n.loginSubtitle,
                            ),
                            const SizedBox(height: 28),
                            AutofillGroup(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.username],
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
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [AutofillHints.password],
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
                                      if (value == null || value.length < 8) {
                                        return l10n.passwordMinLength;
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _RememberCredentialsTile(
                              value: _rememberLogin,
                              label: l10n.loginRememberCredentials,
                              enabled: !isLoading,
                              onChanged: (value) {
                                setState(() => _rememberLogin = value);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppGradientPrimaryButton(
                              label: l10n.loginAction,
                              icon: Icons.login_rounded,
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Divider(
                              color: AppColors.textSecondary.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => BlocProvider.value(
                                              value: context.read<AuthBloc>(),
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
                          ],
                        ),
                      ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const GuestPracticePromoCard(),
                      ],
                    ),
                  ),
                ),
              );
            },
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
