import 'dart:async';

import 'package:craftquest_app/core/compliance/legal_links.dart';
import 'package:craftquest_app/core/config/legal_urls.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/locale/locale_controller.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:craftquest_app/features/auth/data/auth_repository.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/presentation/teacher_upgrade_page.dart';
import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:craftquest_app/features/billing/presentation/ai_credit_packs_page.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/features/profile/domain/avatar_catalog.dart';
import 'package:craftquest_app/features/profile/presentation/change_password_page.dart';
import 'package:craftquest_app/features/profile/presentation/payment_history_page.dart';
import 'package:craftquest_app/features/profile/presentation/widgets/avatar_picker_sheet.dart';
import 'package:craftquest_app/features/profile/presentation/widgets/edit_display_name_dialog.dart';
import 'package:craftquest_app/features/prep_plus/presentation/admin/prep_plus_admin_hub_page.dart';
import 'package:craftquest_app/features/notifications/presentation/notification_preferences_page.dart';
import 'package:craftquest_app/features/profile/presentation/widgets/profile_language_selector.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final UserProfileModel user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = getIt<AuthRepository>();
  final _billingRepository = getIt<BillingRepository>();
  final _localeController = getIt<LocaleController>();
  late String _avatarId;
  String? _displayNameOverride;
  bool _savingAvatar = false;
  bool _savingName = false;
  UserBillingModel? _billing;
  bool _billingLoadScheduled = false;

  bool get _hasProPlan =>
      _billing?.plan.code.toLowerCase() == 'pro' ||
      _billing?.plan.code.toLowerCase() == 'premium';

  bool get _isTeacher => widget.user.roles.contains('teacher');

  @override
  void initState() {
    super.initState();
    _avatarId = widget.user.avatarId ?? AvatarOption.defaultId;
  }

  /// Billing is optional UI on this page — defer so profile edits are not queued behind it.
  void _scheduleBillingLoadIfNeeded() {
    if (_billingLoadScheduled || _billing != null) {
      return;
    }
    _billingLoadScheduled = true;

    if (_billingRepository.hasFreshBillingCache) {
      unawaited(_loadBilling());
      return;
    }

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _billing == null) {
        unawaited(_loadBilling());
      }
    });
  }

  Future<void> _loadBilling() async {
    try {
      final billing = await _billingRepository.getMyBilling();
      if (!mounted) return;
      setState(() => _billing = billing);
    } catch (_) {
      if (!mounted) return;
      setState(() => _billing = null);
    }
  }

  String _proPlanSubtitle(AppLocalizations l10n) {
    if (!_hasProPlan || _billing == null) {
      return l10n.profileProPlanInactiveSubtitle;
    }
    return BillingDisplay.subscriptionStatusLine(
          context,
          l10n,
          subscription: _billing!.subscription,
        ) ??
        l10n.profileProPlanActiveSubtitle;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatarId != widget.user.avatarId) {
      _avatarId = widget.user.avatarId ?? AvatarOption.defaultId;
    }
    if (oldWidget.user.displayName != widget.user.displayName) {
      _displayNameOverride = null;
    }
  }

  Future<void> _openAvatarPicker() async {
    if (_savingAvatar) return;
    await AvatarPickerSheet.show(
      context,
      currentAvatarId: _avatarId,
      onSelected: _selectAvatar,
    );
  }

  Future<void> _selectAvatar(String avatarId) async {
    if (_savingAvatar || avatarId == _avatarId) return;

    setState(() {
      _avatarId = avatarId;
      _savingAvatar = true;
    });

    try {
      final updated = await _repository.updateProfile(avatarId: avatarId);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(updated));
      context.showSuccessSnackBar(
        AppLocalizations.of(context)!.avatarUpdatedMessage,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _avatarId = widget.user.avatarId ?? AvatarOption.defaultId);
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _localeController.setLocale(
        Locale(languageCode),
        persist: true,
      );
      final updated = await _repository.updateProfile(
        preferredLanguage: languageCode,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(updated));
      context.showSuccessSnackBar(l10n.languageUpdatedMessage);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  String _effectiveDisplayName() {
    final override = _displayNameOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    return widget.user.displayName?.trim().isNotEmpty == true
        ? widget.user.displayName!.trim()
        : widget.user.email;
  }

  bool get _canManagePrepPlus =>
      widget.user.roles.contains('content_admin') ||
      widget.user.roles.contains('super_admin');

  Future<void> _editDisplayName() async {
    if (_savingName) return;

    final newName = await EditDisplayNameDialog.show(
      context,
      initialName: widget.user.displayName?.trim() ?? '',
    );

    if (!mounted || newName == null) return;
    if (newName == widget.user.displayName?.trim()) return;

    // Dejar que la ruta del diálogo se retire del overlay antes de reconstruir.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _savingName = true;
      _displayNameOverride = newName;
    });
    try {
      final updated = await _repository.updateProfile(displayName: newName);
      if (!mounted) return;
      setState(() {
        _displayNameOverride = null;
        _savingName = false;
      });
      context.read<AuthBloc>().add(AuthProfileUpdated(updated));
      context.showSuccessSnackBar(l10n.profileNameUpdatedMessage);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _displayNameOverride = null;
        _savingName = false;
      });
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayNameOverride = null;
          _savingName = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountSubtitle),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountConfirmHint,
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.deleteAccountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              final matches = confirmController.text.trim().toUpperCase() ==
                  l10n.deleteAccountConfirmWord.toUpperCase();
              Navigator.of(dialogContext).pop(matches);
            },
            child: Text(l10n.deleteAccountAction),
          ),
        ],
      ),
    );
    confirmController.dispose();

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
    if (!context.mounted) {
      return;
    }
    context.showSuccessSnackBar(l10n.deleteAccountSuccess);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleBillingLoadIfNeeded();
    });

    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = _localeController.locale?.languageCode ??
        widget.user.preferredLanguage ??
        Localizations.localeOf(context).languageCode;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.profileTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          AppSectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openAvatarPicker,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatar(avatarId: _avatarId, size: 56),
                        if (_savingAvatar)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.background.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.accentMint,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _effectiveDisplayName(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 2,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.accentMint,
                            ),
                            onPressed: (_savingAvatar || _savingName)
                                ? null
                                : _editDisplayName,
                            child: Text(l10n.profileEditNameAction),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.accentMint,
                            ),
                            onPressed: _savingAvatar ? null : _openAvatarPicker,
                            child: Text(l10n.profileChangeAvatarAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.languageSectionTitle),
          const SizedBox(height: AppSpacing.xs),
          ProfileLanguageSelector(
            currentLanguageCode: currentLanguage,
            onLanguageSelected: _changeLanguage,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.notificationsPreferencesTitle),
          const SizedBox(height: AppSpacing.xs),
          AppSectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.accentMint,
              ),
              title: Text(
                l10n.notificationsPreferencesTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                l10n.notificationsPreferencesSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationPreferencesPage(),
                  ),
                );
              },
            ),
          ),
          if (_canManagePrepPlus) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSectionTitle(title: l10n.prepAdminProfileSectionTitle),
            const SizedBox(height: AppSpacing.xs),
            AppSectionCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.accentGold,
                ),
                title: Text(l10n.prepAdminProfileAction),
                subtitle: Text(l10n.prepAdminProfileSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrepPlusAdminHubPage(),
                    ),
                  );
                },
              ),
            ),
          ],
          if (!_isTeacher) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSectionTitle(title: l10n.profileProPlanSectionTitle),
            const SizedBox(height: AppSpacing.xs),
            AppSectionCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
                title: Text(
                  _hasProPlan
                      ? l10n.profileProPlanManageTitle
                      : l10n.upgradePlanAction,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _proPlanSubtitle(l10n),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
                onTap: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const UpgradePlanPage(),
                    ),
                  );
                  await _loadBilling();
                },
              ),
            ),
          ],
          if (BillingPlanAccess.canBuyAiCreditPacks(_billing?.plan.code)) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSectionCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.accentViolet,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.aiCreditPacksTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  l10n.aiCreditPacksSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
                onTap: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const AiCreditPacksPage(),
                    ),
                  );
                  await _loadBilling();
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.profileTeacherPlanSectionTitle),
          const SizedBox(height: AppSpacing.xs),
          AppSectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.teacherAccentSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.teacherAccent, size: 20),
              ),
              title: Text(
                _isTeacher
                    ? l10n.profileTeacherPlanManageTitle
                    : l10n.teacherUpgradeCta,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                _isTeacher
                    ? l10n.profileTeacherPlanActiveSubtitle
                    : l10n.profileTeacherPlanInactiveSubtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => TeacherUpgradePage(user: widget.user),
                  ),
                );
                await _loadBilling();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.profilePaymentHistorySectionTitle),
          const SizedBox(height: AppSpacing.xs),
          AppSectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.accentCool,
              ),
              title: Text(l10n.profilePaymentHistoryAction),
              subtitle: Text(l10n.profilePaymentHistorySubtitle),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PaymentHistoryPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.securitySectionTitle),
          const SizedBox(height: AppSpacing.xs),
          AppSectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text(l10n.changePasswordTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                _divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    l10n.logoutAction,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                ),
                _divider(),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.error,
                  ),
                  title: Text(
                    l10n.deleteAccountTitle,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  subtitle: Text(l10n.deleteAccountSubtitle),
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.legalSectionTitle),
          const SizedBox(height: AppSpacing.xs),
          AppSectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyPolicyLink),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => openLegalUrl(LegalUrls.privacyPolicyUrl),
                ),
                _divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.termsOfServiceLink),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => openLegalUrl(LegalUrls.termsOfServiceUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
        color: AppColors.textSecondary.withValues(alpha: 0.12),
      );
}
