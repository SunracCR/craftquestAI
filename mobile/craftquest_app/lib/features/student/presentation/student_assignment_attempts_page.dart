import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';
import 'package:craftquest_app/features/student/data/student_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_attempt_format.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class StudentAssignmentAttemptsPage extends StatefulWidget {
  const StudentAssignmentAttemptsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.quizTitle,
  });

  final String assignmentId;
  final String assignmentTitle;
  final String quizTitle;

  @override
  State<StudentAssignmentAttemptsPage> createState() =>
      _StudentAssignmentAttemptsPageState();
}

class _StudentAssignmentAttemptsPageState
    extends State<StudentAssignmentAttemptsPage> {
  final _repository = getIt<StudentRepository>();
  List<StudentAssignmentAttemptModel>? _attempts;
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
      final attempts =
          await _repository.listMyAssignmentAttempts(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e, AppLocalizations.of(context));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  String _reviewHiddenMessage(
    AppLocalizations l10n,
    String locale,
    StudentAssignmentAttemptModel attempt,
  ) {
    final mode = attempt.assignmentShowCorrectAnswersMode;
    if (mode == 'after_due_date') {
      final dueAt = attempt.assignmentDueAt;
      if (dueAt != null) {
        final dueLabel = AssignmentDates.formatWithLocale(
          locale,
          AssignmentDates.calendarUtc(dueAt),
        );
        return l10n.practiceReviewHiddenUntilDue(dueLabel);
      }
      return l10n.practiceReviewHiddenUntilDueNoDate;
    }
    return l10n.practiceReviewHiddenTeacherOnly;
  }

  String _localizedStatus(AppLocalizations l10n, String status) {
    return switch (status) {
      'finished' => l10n.studentAssignmentAttemptStatusFinished,
      'forfeited' => l10n.studentAssignmentAttemptStatusForfeited,
      _ => status,
    };
  }

  double? _bestPercent(List<StudentAssignmentAttemptModel> attempts) {
    if (attempts.isEmpty) return null;
    var best = 0.0;
    for (final a in attempts) {
      final ratio =
          a.scorePossible > 0 ? a.scoreObtained / a.scorePossible : 0.0;
      if (ratio > best) best = ratio;
    }
    return best;
  }

  void _openAttempt(
    BuildContext context,
    StudentAssignmentAttemptModel attempt,
    AppLocalizations l10n,
    String locale,
  ) {
    if (attempt.canViewDetailedReview) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeacherSessionReviewPage(
            sessionId: attempt.practiceSessionId,
            quizTitle: widget.quizTitle,
            isMyReview: true,
          ),
        ),
      );
      return;
    }

    context.showInfoSnackBar(_reviewHiddenMessage(l10n, locale, attempt));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final attempts = _attempts;
    final canViewReview =
        attempts?.isNotEmpty == true && attempts!.first.canViewDetailedReview;
    final bestPercent = attempts != null ? _bestPercent(attempts) : null;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.studentAssignmentMyAttemptsTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : attempts == null || attempts.isEmpty
                  ? AppEmptyView(
                      message: l10n.studentAssignmentMyAttemptsEmpty,
                      icon: Icons.history_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          AppPageHeader(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.sm,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.assignmentTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.studentAssignmentAttemptsHeaderSummary(
                                      attempts.length,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (bestPercent != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.studentAssignmentAttemptBestScore(
                                        (bestPercent * 100).toStringAsFixed(0),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.accentMint,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (!canViewReview) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.sm,
                              ),
                              child: AppNoticeBanner(
                                message: _reviewHiddenMessage(
                                  l10n,
                                  locale,
                                  attempts.first,
                                ),
                                variant: AppNoticeVariant.info,
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < attempts.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == attempts.length - 1
                                          ? 0
                                          : AppSpacing.sm,
                                    ),
                                    child: _StudentAttemptCard(
                                      attempt: attempts[i],
                                      l10n: l10n,
                                      localizedStatus: _localizedStatus(
                                        l10n,
                                        attempts[i].status,
                                      ),
                                      onTap: () => _openAttempt(
                                        context,
                                        attempts[i],
                                        l10n,
                                        locale,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
    );
  }
}

class _StudentAttemptCard extends StatelessWidget {
  const _StudentAttemptCard({
    required this.attempt,
    required this.l10n,
    required this.localizedStatus,
    required this.onTap,
  });

  final StudentAssignmentAttemptModel attempt;
  final AppLocalizations l10n;
  final String localizedStatus;
  final VoidCallback onTap;

  Color _scoreColor(double obtained, double possible) {
    if (possible <= 0) return AppColors.textSecondary;
    final ratio = obtained / possible;
    if (ratio >= 0.7) return AppColors.accentMint;
    if (ratio >= 0.4) return AppColors.accentGold;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final percent = attempt.scorePossible > 0
        ? (attempt.scoreObtained / attempt.scorePossible * 100)
        : 0.0;
    final percentLabel = percent.toStringAsFixed(0);
    final accent = _scoreColor(attempt.scoreObtained, attempt.scorePossible);
    final canReview = attempt.canViewDetailedReview;
    final duration = formatTeacherAttemptDuration(attempt.durationSeconds);
    final durationLabel =
        duration.isNotEmpty ? duration : '—';
    final scoreLabel =
        '${attempt.scoreObtained.toStringAsFixed(0)}/${attempt.scorePossible.toStringAsFixed(0)}';

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ScoreRing(
                  percentLabel: percentLabel,
                  accent: accent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatTeacherAttemptDate(context, attempt.sortDate),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.studentAssignmentAttemptMeta(
                          scoreLabel,
                          durationLabel,
                          localizedStatus,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                      if (!canReview) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _MetaChip(
                          label: l10n.studentAssignmentAttemptScoreOnlyBadge,
                          color: AppColors.textSecondary,
                          icon: Icons.visibility_off_outlined,
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.xs),
                        _MetaChip(
                          label: l10n.studentAssignmentAttemptReviewAvailable,
                          color: AppColors.accentMint,
                          icon: Icons.fact_check_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  canReview
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: canReview
                      ? AppColors.accentCool.withValues(alpha: 0.9)
                      : AppColors.textSecondary.withValues(alpha: 0.65),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.percentLabel,
    required this.accent,
  });

  final String percentLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
        ),
        child: Center(
          child: Text(
            '$percentLabel%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}
