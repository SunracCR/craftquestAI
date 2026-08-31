import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/presentation/guardian_email_correction_dialog.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ParentalConsentPendingPage extends StatefulWidget {
  const ParentalConsentPendingPage({
    required this.email,
    required this.guardianEmail,
    super.key,
  });

  final String email;
  final String guardianEmail;

  @override
  State<ParentalConsentPendingPage> createState() =>
      _ParentalConsentPendingPageState();
}

class _ParentalConsentPendingPageState extends State<ParentalConsentPendingPage> {
  final _repository = getIt<AuthRepository>();
  bool _isResending = false;
  late String _guardianEmail;

  @override
  void initState() {
    super.initState();
    _guardianEmail = widget.guardianEmail;
  }

  Future<void> _resend() async {
    if (_isResending) {
      return;
    }

    setState(() => _isResending = true);
    try {
      await _repository.resendParentalConsent(email: widget.email);
      if (!mounted) {
        return;
      }
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.parentalConsentResend,
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(_repository.mapError(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _correctGuardianEmail() async {
    final updated = await showGuardianEmailCorrectionDialog(
      context: context,
      minorEmail: widget.email,
      currentGuardianEmail: _guardianEmail,
    );
    if (!mounted || updated == null) {
      return;
    }

    setState(() => _guardianEmail = updated);
    context.showSuccessSnackBar(
      AppLocalizations.of(context)!.correctGuardianEmailSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.parentalConsentPendingTitle),
      body: ListView(
        padding: AppSpacing.pageVertical,
        children: [
          AppBrandHeader(title: l10n.parentalConsentPendingTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.parentalConsentPendingMessage(_guardianEmail),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppGradientPrimaryButton(
            label: l10n.parentalConsentResend,
            isLoading: _isResending,
            onPressed: _resend,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _isResending ? null : _correctGuardianEmail,
            child: Text(l10n.correctGuardianEmailLoginHint),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(l10n.backToLogin),
          ),
        ],
      ),
    );
  }
}
