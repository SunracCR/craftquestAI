import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/update/app_version_repository.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<bool?> showAppVersionRequirementFormSheet(
  BuildContext context, {
  required String platform,
  AppVersionRequirement? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AppVersionRequirementFormSheet(
      platform: platform,
      existing: existing,
    ),
  );
}

class _AppVersionRequirementFormSheet extends StatefulWidget {
  const _AppVersionRequirementFormSheet({
    required this.platform,
    this.existing,
  });

  final String platform;
  final AppVersionRequirement? existing;

  @override
  State<_AppVersionRequirementFormSheet> createState() =>
      _AppVersionRequirementFormSheetState();
}

class _AppVersionRequirementFormSheetState
    extends State<_AppVersionRequirementFormSheet> {
  final _repo = getIt<AppVersionRepository>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minVersionCtrl;
  late final TextEditingController _latestVersionCtrl;
  late final TextEditingController _updateUrlCtrl;
  late final TextEditingController _messageCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _minVersionCtrl =
        TextEditingController(text: e?.minSupportedVersion ?? '');
    _latestVersionCtrl = TextEditingController(text: e?.latestVersion ?? '');
    _updateUrlCtrl = TextEditingController(text: e?.updateUrl ?? '');
    _messageCtrl = TextEditingController(text: e?.message ?? '');
  }

  @override
  void dispose() {
    _minVersionCtrl.dispose();
    _latestVersionCtrl.dispose();
    _updateUrlCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      context.showErrorSnackBar(l10n.prepAdminRequiredField);
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'minSupportedVersion': _minVersionCtrl.text.trim(),
      'latestVersion': _latestVersionCtrl.text.trim().isEmpty
          ? null
          : _latestVersionCtrl.text.trim(),
      'updateUrl': _updateUrlCtrl.text.trim(),
      'message':
          _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    };
    try {
      await _repo.upsertRequirement(widget.platform, body);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(_repo.mapError(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(DioErrorMapper.genericMessage(l10n));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final platformLabel = widget.platform == 'ios' ? 'iOS' : 'Android';

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appVersionAdminFormTitle(platformLabel),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _minVersionCtrl,
                decoration: InputDecoration(
                  labelText: l10n.appVersionAdminMinVersionLabel,
                  hintText: '1.2.0',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.prepAdminRequiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _latestVersionCtrl,
                decoration: InputDecoration(
                  labelText: l10n.appVersionAdminLatestVersionLabel,
                  hintText: '1.2.0',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _updateUrlCtrl,
                decoration: InputDecoration(
                  labelText: l10n.appVersionAdminUpdateUrlLabel,
                ),
                keyboardType: TextInputType.url,
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.prepAdminRequiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _messageCtrl,
                decoration: InputDecoration(
                  labelText: l10n.appVersionAdminMessageLabel,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileSaveAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
