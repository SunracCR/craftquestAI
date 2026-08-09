import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/update/app_version_repository.dart';
import 'package:craftquest_app/core/update/app_version_requirement.dart';
import 'package:craftquest_app/core/update/presentation/app_version_admin_form_sheet.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const _platforms = ['android', 'ios'];

/// Panel simple (super_admin) para gestionar la versión mínima forzada por
/// plataforma. Escritura vía `PUT /api/app-version/{platform}`.
class AppVersionAdminPage extends StatefulWidget {
  const AppVersionAdminPage({super.key});

  @override
  State<AppVersionAdminPage> createState() => _AppVersionAdminPageState();
}

class _AppVersionAdminPageState extends State<AppVersionAdminPage> {
  final _repo = getIt<AppVersionRepository>();
  final Map<String, AppVersionRequirement?> _requirements = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait(
        _platforms.map(_repo.getRequirementForAdmin),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        for (var i = 0; i < _platforms.length; i++) {
          _requirements[_platforms[i]] = results[i];
        }
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _repo.mapError(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  Future<void> _edit(String platform) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showAppVersionRequirementFormSheet(
      context,
      platform: platform,
      existing: _requirements[platform],
    );
    if (saved == true && mounted) {
      context.showSuccessSnackBar(l10n.appVersionAdminSaved);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.appVersionAdminTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: AppSpacing.listBottom,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          l10n.appVersionAdminSubtitle,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      for (final platform in _platforms)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: _PlatformCard(
                            platform: platform,
                            requirement: _requirements[platform],
                            onEdit: () => _edit(platform),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.requirement,
    required this.onEdit,
  });

  final String platform;
  final AppVersionRequirement? requirement;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final req = requirement;

    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                platform == 'ios'
                    ? Icons.apple_rounded
                    : Icons.android_rounded,
                color: AppColors.accentCool,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  platform == 'ios' ? 'iOS' : 'Android',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (req == null)
            Text(
              l10n.appVersionAdminNotConfigured,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            _InfoRow(
              label: l10n.appVersionAdminMinVersionLabel,
              value: req.minSupportedVersion,
            ),
            if (req.latestVersion != null && req.latestVersion!.isNotEmpty)
              _InfoRow(
                label: l10n.appVersionAdminLatestVersionLabel,
                value: req.latestVersion!,
              ),
            _InfoRow(
              label: l10n.appVersionAdminUpdateUrlLabel,
              value: req.updateUrl,
            ),
            if (req.message != null && req.message!.isNotEmpty)
              _InfoRow(
                label: l10n.appVersionAdminMessageLabel,
                value: req.message!,
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
