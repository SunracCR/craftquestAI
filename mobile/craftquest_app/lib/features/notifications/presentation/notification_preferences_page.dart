import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:craftquest_app/features/notifications/presentation/notification_preference_catalog.dart';
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

  void _resetToDefaults() {
    setState(() {
      _preferences = _preferences
          .map(
            (pref) => pref.copyWith(
              inAppEnabled: true,
              pushEnabled: true,
              emailEnabled: notificationDefaultEmailEnabled(pref.type),
            ),
          )
          .toList();
    });
    unawaited(_save());
  }

  NotificationPreferenceModel? _prefFor(String type) {
    for (final pref in _preferences) {
      if (pref.type == type) return pref;
    }
    return null;
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      l10n.notificationsPreferencesSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppNoticeBanner(
                      message: l10n.notificationsPreferencesDefaultsHint,
                      variant: AppNoticeVariant.info,
                      actionLabel: l10n.notificationsPreferencesResetDefaults,
                      onAction: _saving ? null : _resetToDefaults,
                    ),
                    if (_saving) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.accentCool,
                        backgroundColor: AppColors.surfaceHighlight,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ...notificationPreferenceSections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _PreferenceSectionCard(
                          title: _sectionTitle(l10n, section.titleKey),
                          sectionKey: section.titleKey,
                          preferences: section.types
                              .map(_prefFor)
                              .whereType<NotificationPreferenceModel>()
                              .toList(),
                          saving: _saving,
                          typeLabel: (type) => _typeLabel(l10n, type),
                          onChanged: _updatePreference,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _sectionTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'sharing' => l10n.notificationsPreferencesSectionSharing,
      'assignments' => l10n.notificationsPreferencesSectionAssignments,
      'membership' => l10n.notificationsPreferencesSectionMembership,
      'ai' => l10n.notificationsPreferencesSectionAi,
      _ => key,
    };
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

Color _channelAccent(NotificationChannel channel) => switch (channel) {
      NotificationChannel.inApp => AppColors.accentCool,
      NotificationChannel.push => AppColors.accentViolet,
      NotificationChannel.email => AppColors.accentGold,
    };

class _PreferenceSectionCard extends StatelessWidget {
  const _PreferenceSectionCard({
    required this.title,
    required this.sectionKey,
    required this.preferences,
    required this.saving,
    required this.typeLabel,
    required this.onChanged,
  });

  final String title;
  final String sectionKey;
  final List<NotificationPreferenceModel> preferences;
  final bool saving;
  final String Function(String type) typeLabel;
  final void Function(String type, NotificationChannel channel, bool enabled)
      onChanged;

  static const _channelColumnWidth = 56.0;

  Color get _sectionAccent => switch (sectionKey) {
        'membership' => AppColors.accentGold,
        'assignments' => AppColors.accentCool,
        'ai' => AppColors.accentViolet,
        _ => AppColors.accentMint,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppSectionCard(
      variant: sectionKey == 'membership'
          ? AppCardVariant.highlight
          : AppCardVariant.surface,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _sectionAccent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppColors.radiusSm),
                    ),
                  ),
                  child: const SizedBox(width: 4),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: _sectionAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                _ChannelHeader(
                  tooltip: l10n.notificationsChannelInApp,
                  icon: Icons.inbox_outlined,
                  channel: NotificationChannel.inApp,
                ),
                _ChannelHeader(
                  tooltip: l10n.notificationsChannelPush,
                  icon: Icons.notifications_none_rounded,
                  channel: NotificationChannel.push,
                ),
                _ChannelHeader(
                  tooltip: l10n.notificationsChannelEmail,
                  icon: Icons.mail_outline_rounded,
                  channel: NotificationChannel.email,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.14),
          ),
          for (var i = 0; i < preferences.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.textSecondary.withValues(alpha: 0.08),
              ),
            _PreferenceRow(
              label: typeLabel(preferences[i].type),
              preference: preferences[i],
              saving: saving,
              onChanged: onChanged,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.tooltip,
    required this.icon,
    required this.channel,
  });

  final String tooltip;
  final IconData icon;
  final NotificationChannel channel;

  @override
  Widget build(BuildContext context) {
    final accent = _channelAccent(channel);

    return SizedBox(
      width: _PreferenceSectionCard._channelColumnWidth,
      child: Tooltip(
        message: tooltip,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 2),
            Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.label,
    required this.preference,
    required this.saving,
    required this.onChanged,
  });

  final String label;
  final NotificationPreferenceModel preference;
  final bool saving;
  final void Function(String type, NotificationChannel channel, bool enabled)
      onChanged;

  bool get _rowFullyMuted {
    final emailSupported =
        emailEligibleNotificationTypes.contains(preference.type);
    final emailOff = !emailSupported || !preference.emailEnabled;
    return !preference.inAppEnabled && !preference.pushEnabled && emailOff;
  }

  @override
  Widget build(BuildContext context) {
    final supportsEmail =
        emailEligibleNotificationTypes.contains(preference.type);
    final muted = _rowFullyMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      color: muted
          ? Colors.transparent
          : AppColors.surfaceHighlight.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted
                    ? AppColors.textSecondary.withValues(alpha: 0.72)
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          _ChannelSwitch(
            channel: NotificationChannel.inApp,
            value: preference.inAppEnabled,
            enabled: !saving,
            onChanged: (value) =>
                onChanged(preference.type, NotificationChannel.inApp, value),
          ),
          _ChannelSwitch(
            channel: NotificationChannel.push,
            value: preference.pushEnabled,
            enabled: !saving,
            onChanged: (value) =>
                onChanged(preference.type, NotificationChannel.push, value),
          ),
          supportsEmail
              ? _ChannelSwitch(
                  channel: NotificationChannel.email,
                  value: preference.emailEnabled,
                  enabled: !saving,
                  onChanged: (value) => onChanged(
                    preference.type,
                    NotificationChannel.email,
                    value,
                  ),
                )
              : SizedBox(
                  width: _PreferenceSectionCard._channelColumnWidth,
                  child: Center(
                    child: Text(
                      '—',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.28),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ChannelSwitch extends StatelessWidget {
  const _ChannelSwitch({
    required this.channel,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final NotificationChannel channel;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = _channelAccent(channel);

    return SizedBox(
      width: _PreferenceSectionCard._channelColumnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.88,
            child: Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.textPrimary,
              activeTrackColor: accent.withValues(alpha: 0.62),
              inactiveThumbColor: AppColors.textSecondary.withValues(alpha: 0.45),
              inactiveTrackColor: AppColors.background.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
