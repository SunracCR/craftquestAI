import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/parental_consent_pending_page.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_header.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    required this.initialToken,
    this.email,
    this.guardianEmail,
    super.key,
  });

  final String initialToken;
  final String? email;
  final String? guardianEmail;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _repository = getIt<AuthRepository>();
  bool _isSubmitting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    if (_isSubmitting || _completed) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _repository.verifyEmail(token: widget.initialToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _completed = true;
      });
      context.read<AuthBloc>().add(AuthEmailVerified(response.user));
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      final errorCode = _errorCodeFrom(e);
      if (errorCode == 'PARENTAL_CONSENT_PENDING') {
        final email = widget.email ?? '';
        final guardianEmail = widget.guardianEmail ?? email;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ParentalConsentPendingPage(
              email: email,
              guardianEmail: guardianEmail,
            ),
          ),
        );
        return;
      }
      context.showErrorSnackBar(_repository.mapError(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    }
  }

  String? _errorCodeFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['errorCode'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthPremiumBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AuthPremiumHeader(
                      title: l10n.verifyEmailTitle,
                      subtitle: _completed
                          ? l10n.verifyEmailSuccess
                          : l10n.verifyEmailInProgress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else if (!_completed)
                      AppGradientPrimaryButton(
                        label: l10n.verifyEmailRetryAction,
                        onPressed: _verify,
                      ),
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
