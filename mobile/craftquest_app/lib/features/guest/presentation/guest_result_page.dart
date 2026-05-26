import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/auth_bloc.dart';
import 'package:craftquest_app/features/auth/presentation/register_page.dart';
import 'package:craftquest_app/features/guest/presentation/guest_session_navigation.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_score_summary_card.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuestResultPage extends StatelessWidget {
  const GuestResultPage({
    super.key,
    required this.result,
    required this.quizTitle,
    required this.guestVisitId,
    required this.guestToken,
    this.elapsed,
  });

  final PracticeSessionResultModel result;
  final String quizTitle;
  final String guestVisitId;
  final String guestToken;
  final Duration? elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.practiceResultTitle),
        bottomBar: _GuestResultBottomBar(
          l10n: l10n,
          onViewResults: () => _viewResults(context),
          onTryAgain: () => Navigator.of(context).pop(),
          onLeave: () => _confirmLeave(context, l10n),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                quizTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PracticeScoreSummaryCard(
                      percentage: result.percentage,
                      scoreObtained: result.scoreObtained,
                      scorePossible: result.scorePossible,
                      elapsed: elapsed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _StatsStrip(
                      correct: result.correctAnswers,
                      incorrect: result.incorrectAnswers,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CompactRegisterTeaser(
                      l10n: l10n,
                      onTap: () => _goRegister(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewResults(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionReviewPage(
          sessionId: result.practiceSessionId,
          quizTitle: quizTitle,
          isGuestMode: true,
          guestVisitId: guestVisitId,
          guestToken: guestToken,
        ),
      ),
    );
  }

  void _goRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
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
}

class _GuestResultBottomBar extends StatelessWidget {
  const _GuestResultBottomBar({
    required this.l10n,
    required this.onViewResults,
    required this.onTryAgain,
    required this.onLeave,
  });

  final AppLocalizations l10n;
  final VoidCallback onViewResults;
  final VoidCallback onTryAgain;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      children: [
        AppGradientPrimaryButton(
          label: l10n.guestViewResultsAction,
          icon: Icons.fact_check_outlined,
          onPressed: onViewResults,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _SideActionButton(
                label: l10n.guestTryAgainAction,
                icon: Icons.refresh_rounded,
                onPressed: onTryAgain,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SideActionButton(
                label: l10n.guestLeaveAction,
                icon: Icons.logout_rounded,
                onPressed: onLeave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentWarm,
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.correct,
    required this.incorrect,
    required this.l10n,
  });

  final int correct;
  final int incorrect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_rounded,
            label: l10n.guestResultStatCorrect,
            value: '$correct',
            color: AppColors.accentMint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.cancel_rounded,
            label: l10n.guestResultStatIncorrect,
            value: '$incorrect',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactRegisterTeaser extends StatelessWidget {
  const _CompactRegisterTeaser({
    required this.l10n,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.accentGold.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: AppColors.accentGold, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.guestRegisterCtaTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        l10n.guestRegisterAction,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accentWarm,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentGold],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.guestShellFreeBadge.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentGold.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
