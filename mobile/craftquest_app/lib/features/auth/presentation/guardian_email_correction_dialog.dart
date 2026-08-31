import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Dialog to correct the guardian email while parental consent is pending.
Future<String?> showGuardianEmailCorrectionDialog({
  required BuildContext context,
  required String minorEmail,
  required String currentGuardianEmail,
}) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _GuardianEmailCorrectionDialog(
      minorEmail: minorEmail,
      initialGuardianEmail: currentGuardianEmail,
    ),
  );
}

class _GuardianEmailCorrectionDialog extends StatefulWidget {
  const _GuardianEmailCorrectionDialog({
    required this.minorEmail,
    required this.initialGuardianEmail,
  });

  final String minorEmail;
  final String initialGuardianEmail;

  @override
  State<_GuardianEmailCorrectionDialog> createState() =>
      _GuardianEmailCorrectionDialogState();
}

class _GuardianEmailCorrectionDialogState
    extends State<_GuardianEmailCorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = getIt<AuthRepository>();
  late final TextEditingController _guardianEmailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _guardianEmailController =
        TextEditingController(text: widget.initialGuardianEmail);
  }

  @override
  void dispose() {
    _guardianEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final updated = await _repository.updateGuardianEmail(
        email: widget.minorEmail,
        guardianEmail: _guardianEmailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(_repository.mapError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(DioErrorMapper.genericMessage());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.correctGuardianEmailTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.correctGuardianEmailSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _guardianEmailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.guardianEmailLabel,
                hintText: l10n.guardianEmailHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.parentalGateCancel),
        ),
        AppGradientPrimaryButton(
          label: l10n.correctGuardianEmailAction,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
