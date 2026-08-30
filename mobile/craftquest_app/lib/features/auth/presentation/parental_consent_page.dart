import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/presentation/auth_entry_navigation.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_background.dart';
import 'package:craftquest_app/features/auth/presentation/widgets/auth_premium_header.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ParentalConsentPage extends StatefulWidget {
  const ParentalConsentPage({required this.initialToken, super.key});

  final String initialToken;

  @override
  State<ParentalConsentPage> createState() => _ParentalConsentPageState();
}

class _ParentalConsentPageState extends State<ParentalConsentPage> {
  final _repository = getIt<AuthRepository>();
  bool _isSubmitting = false;
  ParentalConsentGrantResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantConsent());
  }

  Future<void> _grantConsent() async {
    if (_isSubmitting || _result != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.grantParentalConsent(
        token: widget.initialToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _result = result;
      });
      clearWebEntryDeepLinkUrl();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(_repository.mapError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    }
  }

  String _successMessage(AppLocalizations l10n) {
    return switch (_result) {
      ParentalConsentGrantResult.accountActivated =>
        l10n.parentalConsentGrantSuccess,
      ParentalConsentGrantResult.consentGrantedPendingEmail =>
        l10n.parentalConsentGrantSuccessPendingEmail,
      null => l10n.parentalConsentGrantInProgress,
    };
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
                      title: l10n.parentalConsentGrantTitle,
                      subtitle: _result == null
                          ? l10n.parentalConsentGrantInProgress
                          : _successMessage(l10n),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else if (_result == null)
                      AppGradientPrimaryButton(
                        label: l10n.parentalConsentGrantRetryAction,
                        onPressed: _grantConsent,
                      )
                    else ...[
                      AppGradientPrimaryButton(
                        label: l10n.parentalConsentGrantDoneAction,
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.pop();
                            return;
                          }
                          returnToLogin(context);
                        },
                      ),
                    ],
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
