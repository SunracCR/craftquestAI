import 'dart:async';

import 'package:craftquest_app/core/navigation/safe_navigation.dart';
import 'package:craftquest_app/core/utils/user_role_labels.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_highlight_stat_row.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/user_avatar.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/core/utils/home_teacher_banner_prefs.dart';
import 'package:craftquest_app/features/auth/data/models/auth_models.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:craftquest_app/features/billing/presentation/teacher_upgrade_page.dart';
import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:craftquest_app/features/billing/presentation/ai_credit_packs_page.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_hub_page.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_list_page.dart';
import 'package:craftquest_app/features/sharing/presentation/accessible_quizzes_page.dart';
import 'package:craftquest_app/features/sharing/presentation/redeem_code_page.dart';
import 'package:craftquest_app/features/student/presentation/student_assignments_page.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user, this.onOpenPrepPlus});

  final UserProfileModel user;
  final VoidCallback? onOpenPrepPlus;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserBillingModel? _billing;
  bool _teacherBannerHidden = true;

  bool get _showTeacherBanner =>
      !_teacherBannerHidden &&
      !widget.user.roles.contains('teacher') &&
      (_billing == null || _billing!.plan.code != 'teacher');

  String? get _planCode => _billing?.plan.code;

  bool get _isProPlan =>
      _planCode != null && _planCode!.toLowerCase() == 'pro';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initHome());
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initHome(forceRefreshBilling: true));
      });
    }
  }

  Future<void> _initHome({bool forceRefreshBilling = false}) async {
    await _load(forceRefresh: forceRefreshBilling);
    await _refreshBannerVisibility(markShownIfVisible: true);
  }

  Future<void> _refreshBannerVisibility({bool markShownIfVisible = false}) async {
    final hiddenByPrefs = await HomeTeacherBannerPrefs.isHidden(
      userId: widget.user.userId,
      planCode: _planCode,
    );
    if (!mounted) return;

    final eligible = !widget.user.roles.contains('teacher') &&
        (_billing == null || _billing!.plan.code != 'teacher');
    final willShow = !hiddenByPrefs && eligible;

    if (willShow && markShownIfVisible) {
      await HomeTeacherBannerPrefs.markSuppressedForCurrentPeriod(
        userId: widget.user.userId,
        planCode: _planCode,
      );
    }

    setState(() => _teacherBannerHidden = !willShow);
  }

  Future<void> _dismissBanner() async {
    await HomeTeacherBannerPrefs.dismiss(
      userId: widget.user.userId,
      planCode: _planCode,
    );
    if (mounted) setState(() => _teacherBannerHidden = true);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final billing = await getIt<BillingRepository>().getMyBilling(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _billing = billing);
    } catch (_) {
      if (!mounted) return;
      setState(() => _billing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planLabel = _billing == null
        ? null
        : BillingDisplay.localizedPlanName(
            l10n,
            code: _billing!.plan.code,
            name: _billing!.plan.name,
          );
    final rolesLabel =
        UserRoleLabels.formatRoles(widget.user.roles, l10n);
    final isTeacher = widget.user.roles.contains('teacher');
    final subscriptionRenewalLine = _billing == null
        ? null
        : BillingDisplay.subscriptionStatusLine(
            context,
            l10n,
            subscription: _billing!.subscription,
          );

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.appTitle,
        actions: const [NotificationBellAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _load();
          await _refreshBannerVisibility(markShownIfVisible: true);
          if (mounted) {
            await getIt<NotificationsCubit>().refreshUnreadCount();
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppPageHeader(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      avatarId: widget.user.avatarId,
                      size: 52,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeWelcomeUser(
                              widget.user.displayName ?? widget.user.email,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppStatusChip(
                            label: l10n.homeRoleLabel(rolesLabel),
                            color: isTeacher
                                ? AppColors.teacherAccent
                                : AppColors.accentCool,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner Profesor — primer elemento visible, sin scroll
            if (_showTeacherBanner)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: _TeacherProminentBanner(
                  user: widget.user,
                  onUpgraded: () async {
                    await _load();
                    await _refreshBannerVisibility(markShownIfVisible: true);
                  },
                  onDismiss: _dismissBanner,
                  dismissTooltip: _isProPlan
                      ? l10n.homeTeacherBannerDismissTooltipMonthly
                      : l10n.homeTeacherBannerDismissTooltipWeekly,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionTitle(title: l10n.aiGenerationHubTitle),
                  const SizedBox(height: AppSpacing.xs),
                  AppSectionCard(
                    variant: AppCardVariant.highlight,
                    padding: EdgeInsets.zero,
                    child: AppActionTile(
                      icon: Icons.auto_awesome_rounded,
                      label: l10n.aiGenerationHubAction,
                      iconColor: AppColors.accentMint,
                      iconBackgroundColor:
                          AppColors.accentMint.withValues(alpha: 0.2),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AiGenerationHubPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionTitle(title: l10n.homePrepPlusCardTitle),
                  const SizedBox(height: AppSpacing.xs),
                  AppSectionCard(
                    variant: AppCardVariant.highlight,
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.accentGold,
                      ),
                      title: Text(l10n.homePrepPlusCardTitle),
                      subtitle: Text(l10n.homePrepPlusCardSubtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: widget.onOpenPrepPlus,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionTitle(title: l10n.myQuizzesAction),
                  const SizedBox(height: AppSpacing.xs),
                  AppSectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        AppActionTile(
                          icon: Icons.quiz_rounded,
                          label: l10n.myQuizzesAction,
                          iconColor: AppColors.accent,
                          iconBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.2),
                          onTap: () {
                            SafeNavigation.pushPage(
                              context,
                              const QuizListPage(),
                            );
                          },
                        ),
                        _divider(),
                        AppActionTile(
                          icon: Icons.library_books_rounded,
                          label: l10n.accessibleQuizzesAction,
                          iconColor: AppColors.accentViolet,
                          iconBackgroundColor:
                              AppColors.accentViolet.withValues(alpha: 0.2),
                          onTap: () {
                            SafeNavigation.pushPage(
                              context,
                              const AccessibleQuizzesPage(),
                            );
                          },
                        ),
                        _divider(),
                        AppActionTile(
                          icon: Icons.school_outlined,
                          label: l10n.studentAssignmentsAction,
                          iconColor: AppColors.accentCool,
                          iconBackgroundColor:
                              AppColors.accentCool.withValues(alpha: 0.2),
                          onTap: () {
                            SafeNavigation.pushPage(
                              context,
                              const StudentAssignmentsPage(),
                            );
                          },
                        ),
                        _divider(),
                        AppActionTile(
                          icon: Icons.vpn_key_rounded,
                          label: l10n.redeemCodeAction,
                          iconColor: AppColors.accentGold,
                          iconBackgroundColor:
                              AppColors.accentGold.withValues(alpha: 0.22),
                          onTap: () {
                            SafeNavigation.pushPage(
                              context,
                              const RedeemCodePage(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_billing != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppSectionTitle(
                      title: l10n.billingPlanLabel(planLabel!),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppSectionCard(
                      variant: AppCardVariant.highlight,
                      padding: EdgeInsets.zero,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accentGold,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(AppColors.radiusSm),
                                ),
                              ),
                              child: const SizedBox(width: 4),
                            ),
                            Expanded(
                              child: Padding(
                                padding: AppColors.paddingMd,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            planLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        AppStatusChip(
                                          label: l10n.billingPlanChipLabel,
                                          color: AppColors.accentGold,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      BillingDisplay.formatQuizzesUsage(
                                        l10n,
                                        quizzesCreated:
                                            _billing!.usage.quizzesCreated,
                                        maxQuizzes:
                                            _billing!.entitlements.maxQuizzes,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppHighlightStatRow(
                                      icon: Icons.auto_awesome_outlined,
                                      label: l10n.billingCreditsLabel(
                                        _billing!.credits.aiCredits,
                                      ),
                                      value: '${_billing!.credits.aiCredits}',
                                      color: AppColors.accentViolet,
                                    ),
                                    if (subscriptionRenewalLine != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        subscriptionRenewalLine,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    AppGradientPrimaryButton(
                                      label: l10n.upgradePlanAction,
                                      icon: Icons.rocket_launch_rounded,
                                      onPressed: () async {
                                        final upgraded =
                                            await Navigator.of(context)
                                                .push<bool>(
                                          MaterialPageRoute<bool>(
                                            builder: (_) =>
                                                const UpgradePlanPage(),
                                          ),
                                        );
                                        if (upgraded == true) {
                                          await _load();
                                        }
                                      },
                                    ),
                                    if (BillingPlanAccess.canBuyAiCreditPacks(
                                      _billing?.plan.code,
                                    )) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final bought =
                                              await Navigator.of(context)
                                                  .push<bool>(
                                            MaterialPageRoute<bool>(
                                              builder: (_) =>
                                                  const AiCreditPacksPage(),
                                            ),
                                          );
                                          if (bought == true) {
                                            await _load();
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.auto_awesome_outlined,
                                        ),
                                        label: Text(l10n.homeBuyAiCreditsAction),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
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

class _TeacherProminentBanner extends StatelessWidget {
  const _TeacherProminentBanner({
    required this.user,
    required this.onUpgraded,
    required this.onDismiss,
    required this.dismissTooltip,
  });

  final UserProfileModel user;
  final Future<void> Function() onUpgraded;
  final VoidCallback onDismiss;
  final String dismissTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.teacherAccentSurface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.teacherAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          // Decoración geométrica de fondo
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.school_rounded,
              size: 90,
              color: AppColors.teacherAccent.withValues(alpha: 0.06),
            ),
          ),
          // Contenido principal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 40, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teacherAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.teacherAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeTeacherBannerTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.homeTeacherBannerBody,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teacherAccent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () async {
                            final upgraded =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TeacherUpgradePage(user: user),
                              ),
                            );
                            if (upgraded == true) {
                              await onUpgraded();
                            }
                          },
                          child: Text(l10n.homeTeacherBannerAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botón X — descartar
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
              tooltip: dismissTooltip,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: onDismiss,
            ),
          ),
        ],
      ),
    );
  }
}
