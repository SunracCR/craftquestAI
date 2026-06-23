import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/features/guest/data/guest_models.dart';
import 'package:craftquest_app/features/guest/data/guest_repository.dart';
import 'package:craftquest_app/features/guest/presentation/guest_practice_navigation.dart';
import 'package:craftquest_app/features/guest/presentation/guest_session_navigation.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuestShellPage extends StatefulWidget {
  const GuestShellPage({super.key, required this.visit});

  final GuestVisitModel visit;

  @override
  State<GuestShellPage> createState() => _GuestShellPageState();
}

class _GuestShellPageState extends State<GuestShellPage>
    with WidgetsBindingObserver {
  late GuestVisitModel _visit;
  List<GuestAttemptModel> _attempts = [];
  bool _loadingAttempts = false;
  bool _startingPractice = false;
  bool _randomize = false;

  static const _heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A4550),
      Color(0xFF1E3540),
      AppColors.background,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const _ctaGradient = LinearGradient(
    colors: [AppColors.accent, AppColors.accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    WidgetsBinding.instance.addObserver(this);
    _loadAttempts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAttempts();
    }
  }

  Future<void> _loadAttempts() async {
    setState(() => _loadingAttempts = true);
    try {
      final repo = getIt<GuestRepository>();
      final attempts = await repo.listAttempts(
        visitId: _visit.guestVisitId,
        token: _visit.token,
      );
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _loadingAttempts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAttempts = false);
    }
  }

  Future<void> _startPractice(BuildContext context) async {
    if (_startingPractice) return;
    setState(() => _startingPractice = true);
    try {
      await openGuestPracticeSession(
        context,
        visitId: _visit.guestVisitId,
        token: _visit.token,
        quizTitle: _visit.quizTitle,
        randomizeQuestions: _randomize ? true : null,
        showElapsedTimer: false,
      );
      if (mounted) await _loadAttempts();
    } finally {
      if (mounted) setState(() => _startingPractice = false);
    }
  }

  Future<void> _openReview(
    BuildContext context,
    GuestAttemptModel attempt,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionReviewPage(
          sessionId: attempt.practiceSessionId,
          quizTitle: _visit.quizTitle,
          isGuestMode: true,
          guestVisitId: _visit.guestVisitId,
          guestToken: _visit.token,
        ),
      ),
    );
  }

  void _goRegister(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: const RegisterPage(),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, AppLocalizations l10n) async {
    if (!await confirmLeaveGuestSession(context, l10n)) return;
    if (!context.mounted) return;
    await leaveGuestSessionAndExit(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmLeave(context, l10n);
      },
      child: EdgeAwareScaffold(
        appBar: craftQuestAppBar(
          title: _visit.quizTitle,
          actions: [
            TextButton(
              onPressed: () => _confirmLeave(context, l10n),
              child: Text(
                l10n.guestLeaveAction,
                style: const TextStyle(
                  color: AppColors.accentWarm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        bottomBar: AppBottomActionBar(
          children: [
            AppGradientPrimaryButton(
              label: l10n.guestStartPracticeAction,
              icon: Icons.play_arrow_rounded,
              isLoading: _startingPractice,
              onPressed: _startingPractice ? null : () => _startPractice(context),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: _heroGradient),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _GuestHeroCard(
                title: _visit.quizTitle,
                questionCount: _visit.questionCount,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.lg),
              _GuestRegisterCtaCard(
                l10n: l10n,
                onRegister: () => _goRegister(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSectionTitle(title: l10n.guestPracticeOptions),
              const SizedBox(height: AppSpacing.xs),
              AppSectionCard(
                variant: AppCardVariant.highlight,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _GuestOptionTile(
                      icon: Icons.shuffle_rounded,
                      iconColor: AppColors.accentViolet,
                      title: l10n.practiceRandomizeQuestionsLabel,
                      subtitle: l10n.practiceRandomizeQuestionsHint,
                      value: _randomize,
                      onChanged: (v) => setState(() => _randomize = v),
                    ),
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: AppColors.textSecondary.withValues(alpha: 0.12),
                    ),
                    _GuestLockedOptionTile(
                      l10n: l10n,
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.accentCool,
                      title: l10n.practiceShowTimerLabel,
                      hint: l10n.guestTimerRegisteredOnlyHint,
                      freeBadge: l10n.guestShellFreeBadge,
                      onUnlock: () => _goRegister(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_attempts.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.guestAttemptsTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentMint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${_attempts.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.accentMint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._attempts.map(
                  (a) => _GuestAttemptTile(
                    attempt: a,
                    l10n: l10n,
                    onTap: () => _openReview(context, a),
                  ),
                ),
              ] else if (_loadingAttempts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else
                _GuestEmptyAttemptsCard(l10n: l10n),
              const SizedBox(height: AppSpacing.lg),
              _GuestEphemeralFooter(l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestHeroCard extends StatelessWidget {
  const _GuestHeroCard({
    required this.title,
    required this.questionCount,
    required this.l10n,
  });

  final String title;
  final int questionCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHighlight.withValues(alpha: 0.95),
            AppColors.surface.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  gradient: _GuestShellPageState._ctaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Chip(
                          label: l10n.guestShellSessionBadge,
                          icon: Icons.person_outline_rounded,
                          color: AppColors.accentSky,
                        ),
                        _Chip(
                          label: l10n.quizQuestionsCount(questionCount),
                          icon: Icons.format_list_numbered_rounded,
                          color: AppColors.accentViolet,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.guestShellHeroHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestRegisterCtaCard extends StatelessWidget {
  const _GuestRegisterCtaCard({
    required this.l10n,
    required this.onRegister,
  });

  final AppLocalizations l10n;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accentGold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppColors.accentGold, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.guestRegisterCtaTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: _GuestShellPageState._ctaGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.guestShellFreeBadge.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _BenefitRow(text: l10n.guestRegisterBenefit1),
          _BenefitRow(text: l10n.guestRegisterBenefit2),
          _BenefitRow(text: l10n.guestRegisterBenefit3),
          _BenefitRow(text: l10n.guestRegisterBenefit4),
          _BenefitRow(text: l10n.guestRegisterBenefit5),
          _BenefitRow(text: l10n.guestRegisterBenefit6),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: l10n.guestRegisterAction,
            icon: Icons.arrow_forward_rounded,
            accentColor: AppColors.accentGold,
            onPressed: onRegister,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.accentMint.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.accentMint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestOptionTile extends StatelessWidget {
  const _GuestOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.accent,
      secondary: _OptionIcon(icon: icon, color: iconColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _GuestLockedOptionTile extends StatelessWidget {
  const _GuestLockedOptionTile({
    required this.l10n,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.hint,
    required this.freeBadge,
    required this.onUnlock,
  });

  final AppLocalizations l10n;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String hint;
  final String freeBadge;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUnlock,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppColors.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _OptionIcon(
                    icon: icon,
                    color: iconColor.withValues(alpha: 0.45),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.accentGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            freeBadge.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.guestRegisterAction,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.accentWarm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accentGold.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _GuestEmptyAttemptsCard extends StatelessWidget {
  const _GuestEmptyAttemptsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSectionCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.accentCool.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              size: 32,
              color: AppColors.accentWarm,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.guestAttemptsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GuestAttemptTile extends StatelessWidget {
  const _GuestAttemptTile({
    required this.attempt,
    required this.l10n,
    required this.onTap,
  });

  final GuestAttemptModel attempt;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = attempt.percentage;
    final color = pct >= 70
        ? AppColors.accentMint
        : pct >= 40
            ? AppColors.accent
            : AppColors.accentSky;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 3,
                        backgroundColor: color.withValues(alpha: 0.12),
                        color: color,
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.practiceScoreLabel(
                          attempt.scoreObtained,
                          attempt.scorePossible,
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        attempt.finishedAt != null
                            ? _formatDate(context, attempt.finishedAt!)
                            : l10n.practiceStatusInProgress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.insights_rounded,
                  color: color.withValues(alpha: 0.85),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) =>
      AssignmentDates.formatDateTime(context, dt);
}

class _GuestEphemeralFooter extends StatelessWidget {
  const _GuestEphemeralFooter({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                l10n.guestEphemeralNotice,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.75),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
