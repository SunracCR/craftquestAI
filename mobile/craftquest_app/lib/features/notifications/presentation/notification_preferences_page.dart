import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final _repository = getIt<NotificationRepository>();

  List<NotificationPreferenceModel> _preferences = [];
  bool _loading = true;
  bool _saving = false;
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
      final result = await _repository.getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = result.preferences;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.mapAny(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.mapAny(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.updatePreferences(_preferences);
      if (!mounted) return;
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.notificationsPreferencesSaved,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.mapAny(e));
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.mapAny(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updatePreference(
    String type,
    NotificationChannel channel,
    bool enabled,
  ) {
    setState(() {
      _preferences = _preferences
          .map(
            (pref) {
              if (pref.type != type) return pref;
              return switch (channel) {
                NotificationChannel.inApp =>
                  pref.copyWith(inAppEnabled: enabled),
                NotificationChannel.push =>
                  pref.copyWith(pushEnabled: enabled),
                NotificationChannel.email =>
                  pref.copyWith(emailEnabled: enabled),
              };
            },
          )
          .toList();
    });
    unawaited(_save());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.notificationsPreferencesTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(
                      l10n.notificationsPreferencesSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._preferences.map(
                      (pref) => _PreferenceCard(
                        title: _typeLabel(l10n, pref.type),
                        preference: pref,
                        saving: _saving,
                        onChanged: (channel, enabled) =>
                            _updatePreference(pref.type, channel, enabled),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'quiz_shared' => l10n.notificationTypeQuizShared,
      'class_joined' => l10n.notificationTypeClassJoined,
      'assignment_created' => l10n.notificationTypeAssignmentCreated,
      'assignment_due_soon' => l10n.notificationTypeAssignmentDueSoon,
      'ai_job_completed' => l10n.notificationTypeAiJobCompleted,
      'ai_job_failed' => l10n.notificationTypeAiJobFailed,
      'membership_expiring' => l10n.notificationTypeMembershipExpiring,
      'membership_expired' => l10n.notificationTypeMembershipExpired,
      _ => type,
    };
  }
}

enum NotificationChannel { inApp, push, email }

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.title,
    required this.preference,
    required this.saving,
    required this.onChanged,
  });

  final String title;
  final NotificationPreferenceModel preference;
  final bool saving;
  final void Function(NotificationChannel channel, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsChannelInApp),
              value: preference.inAppEnabled,
              onChanged: saving
                  ? null
                  : (value) => onChanged(NotificationChannel.inApp, value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsChannelPush),
              value: preference.pushEnabled,
              onChanged: saving
                  ? null
                  : (value) => onChanged(NotificationChannel.push, value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsChannelEmail),
              value: preference.emailEnabled,
              onChanged: saving
                  ? null
                  : (value) => onChanged(NotificationChannel.email, value),
            ),
          ],
        ),
      ),
    );
  }
}
