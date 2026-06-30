import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/compliance/birth_date_correction.dart';
import 'package:craftquest_app/core/compliance/legal_links.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/parental_consent_pending_page.dart';
import 'package:craftquest_app/features/auth/presentation/verify_email_pending_page.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/oauth_sign_in_buttons.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageStorage = getIt<AgeCollectionStorage>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  DateTime? _birthDate;
  bool _isMinor = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStoredBirthDate();
  }

  Future<void> _loadStoredBirthDate() async {
    final stored = await _ageStorage.getDateOfBirth();
    final minor = await _ageStorage.isMinor();
    if (!mounted || stored == null) {
      return;
    }
    setState(() {
      _birthDate = stored;
      _isMinor = minor;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await BirthDateCorrection.pickDate(
      context,
      initialDate: _birthDate,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _birthDate = picked;
      _isMinor = BirthDateCorrection.isMinor(picked);
    });
    await _ageStorage.saveDateOfBirth(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_birthDate == null) {
      AppSnackBars.showError(
        AppLocalizations.of(context)!.ageScreenBirthDateLabel,
      );
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
        dateOfBirth: _birthDate,
        guardianEmail: _isMinor ? _guardianEmailController.text.trim() : null,
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
          builder: (_) => VerifyEmailPendingPage(
            email: result.email,
            guardianEmail: result.guardianEmail,
          ),
        ),
      );
      if (!context.mounted || !result.requiresParentalConsent) {
        return;
      }
      if (result.guardianEmail != null && result.guardianEmail!.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ParentalConsentPendingPage(
              email: result.email,
              guardianEmail: result.guardianEmail!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formattedBirthDate = _birthDate == null
        ? null
        : DateFormat.yMMMMd(locale).format(_birthDate!);

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
              const SizedBox(height: AppSpacing.md),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.ageScreenBirthDateLabel,
                ),
                isEmpty: _birthDate == null,
                child: InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          formattedBirthDate ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isMinor) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.ageScreenMinorNotice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accentCool,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _guardianEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.guardianEmailLabel,
                    hintText: l10n.guardianEmailHint,
                  ),
                  validator: (value) {
                    if (!_isMinor) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
              ],
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
              const RegisterLegalDisclaimer(),
            ],
          ),
        ),
    );
  }
}
