import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_header.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ConfirmPasswordChangePage extends StatefulWidget {
  const ConfirmPasswordChangePage({required this.initialToken, super.key});

  final String initialToken;

  @override
  State<ConfirmPasswordChangePage> createState() =>
      _ConfirmPasswordChangePageState();
}

class _ConfirmPasswordChangePageState extends State<ConfirmPasswordChangePage> {
  final _repository = getIt<AuthRepository>();
  bool _isSubmitting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    if (_isSubmitting || _completed) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.confirmPasswordChange(token: widget.initialToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _completed = true;
      });
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.confirmPasswordChangeSuccess,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(_repository.mapError(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    }
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
                      title: l10n.confirmPasswordChangeTitle,
                      subtitle: _completed
                          ? l10n.confirmPasswordChangeSuccess
                          : l10n.confirmPasswordChangeInProgress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else if (!_completed)
                      AppGradientPrimaryButton(
                        label: l10n.confirmPasswordChangeRetryAction,
                        onPressed: _confirm,
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
