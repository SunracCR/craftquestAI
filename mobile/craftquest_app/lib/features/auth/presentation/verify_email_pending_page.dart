import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class VerifyEmailPendingPage extends StatefulWidget {
  const VerifyEmailPendingPage({required this.email, super.key});

  final String email;

  @override
  State<VerifyEmailPendingPage> createState() => _VerifyEmailPendingPageState();
}

class _VerifyEmailPendingPageState extends State<VerifyEmailPendingPage> {
  final _repository = getIt<AuthRepository>();
  bool _isResending = false;

  Future<void> _resend() async {
    if (_isResending) {
      return;
    }

    setState(() => _isResending = true);
    try {
      await _repository.resendVerification(email: widget.email);
      if (!mounted) {
        return;
      }
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.verifyEmailResentMessage,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.verifyEmailPendingTitle),
      body: ListView(
        padding: AppSpacing.pageVertical,
        children: [
          AppBrandHeader(title: l10n.verifyEmailPendingTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.verifyEmailPendingMessage(widget.email),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppGradientPrimaryButton(
            label: l10n.verifyEmailResendAction,
            isLoading: _isResending,
            onPressed: _resend,
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
