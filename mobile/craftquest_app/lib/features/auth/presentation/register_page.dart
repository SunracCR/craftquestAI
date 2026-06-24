import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/verify_email_pending_page.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/oauth_sign_in_buttons.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final bloc = context.read<AuthBloc>();
    setState(() => _isSubmitting = true);

    final resultFuture = bloc.stream.firstWhere(
      (state) =>
          state is AuthEmailVerificationPending || state is AuthFailure,
    );

    bloc.add(
      AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      ),
    );

    final result = await resultFuture;
    if (!context.mounted) return;
    setState(() => _isSubmitting = false);

    if (result is AuthFailure) {
      AppSnackBars.showError(result.message);
      return;
    }

    if (result is AuthEmailVerificationPending) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailPendingPage(email: result.email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.registerTitle),
      body: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.pageVertical,
            children: [
              AppBrandHeader(title: l10n.registerTitle),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _displayNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.displayNameLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return l10n.passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppGradientPrimaryButton(
                label: l10n.registerAction,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              OAuthSignInButtons(
                enabled: !_isSubmitting,
                forceGoogleAccountSelection: true,
              ),
            ],
          ),
        ),
    );
  }
}
