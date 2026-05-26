import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/widgets/app_highlight_stat_row.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';
import 'package:craftquest_app/features/student/data/student_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class StudentAssignmentProgressPage extends StatefulWidget {
  const StudentAssignmentProgressPage({
    super.key,
    required this.assignmentId,
    required this.quizTitle,
  });

  final String assignmentId;
  final String quizTitle;

  @override
  State<StudentAssignmentProgressPage> createState() =>
      _StudentAssignmentProgressPageState();
}

class _StudentAssignmentProgressPageState
    extends State<StudentAssignmentProgressPage> {
  final _repo = getIt<StudentRepository>();
  late Future<StudentAssignmentSummaryModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getMyAssignmentSummary(widget.assignmentId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.getMyAssignmentSummary(widget.assignmentId);
    });
    await _future;
  }

  Color _scoreColor(double pct) {
    if (pct >= 70) return AppColors.accentMint;
    if (pct >= 40) return AppColors.accentGold;
    return AppColors.error;
  }

  String _reviewHiddenMessage(
    AppLocalizations l10n,
    String locale,
    StudentAssignmentSummaryModel summary,
  ) {
    final mode = summary.assignmentShowCorrectAnswersMode;
    if (mode == 'after_due_date') {
      final dueAt = summary.assignmentDueAt;
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

  void _openAttempt(
    BuildContext context,
    StudentAssignmentSummaryModel summary,
    AssignmentAttemptTrendModel attempt,
    AppLocalizations l10n,
    String locale,
  ) {
    if (summary.canViewDetailedReview) {
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

    context.showInfoSnackBar(_reviewHiddenMessage(l10n, locale, summary));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.studentAssignmentProgressTitle),
      body: FutureBuilder<StudentAssignmentSummaryModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: snapshot.error is DioException
                  ? DioErrorMapper.map(
                      snapshot.error as DioException,
                      l10n,
                    )
                  : DioErrorMapper.genericMessage(l10n),
              retryLabel: l10n.retry,
              onRetry: _reload,
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reload,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.assignmentTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.quizTitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!data.canViewDetailedReview) ...[
                        AppNoticeBanner(
                          message: _reviewHiddenMessage(l10n, locale, data),
                          variant: AppNoticeVariant.info,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppSectionTitle(
                        title: l10n.studentAssignmentProgressMyStats,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSectionCard(
                        child: Column(
                          children: [
                            if (data.bestPercentage != null)
                              AppHighlightStatRow(
                                icon: Icons.emoji_events_outlined,
                                label: l10n.myQuizAnalyticsBestLabel(
                                  data.bestPercentage!,
                                ),
                                value:
                                    '${data.bestPercentage!.toStringAsFixed(0)}%',
                                color: AppColors.accentMint,
                              ),
                            if (data.averagePercentage != null)
                              AppHighlightStatRow(
                                icon: Icons.analytics_outlined,
                                label: l10n.myQuizAnalyticsAverageLabel(
                                  data.averagePercentage!,
                                ),
                                value:
                                    '${data.averagePercentage!.toStringAsFixed(0)}%',
                                color: AppColors.accentGold,
                              ),
                            AppHighlightStatRow(
                              icon: Icons.replay_rounded,
                              label: l10n.myQuizAnalyticsAttemptsLabel(
                                data.finishedAttempts,
                              ),
                              value: '${data.finishedAttempts}',
                              color: AppColors.accentCool,
                            ),
                          ],
                        ),
                      ),
                      if (data.canViewDetailedReview &&
                          data.scoreTrend != null &&
                          data.scoreTrend! > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppNoticeBanner(
                          message: l10n.studentAssignmentProgressTrendUp(
                            data.scoreTrend!.toStringAsFixed(0),
                          ),
                          variant: AppNoticeVariant.success,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppSectionTitle(
                        title: l10n.studentAssignmentProgressEvolutionTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...data.attemptTrend.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppSectionCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              onTap: () => _openAttempt(
                                context,
                                data,
                                t,
                                l10n,
                                locale,
                              ),
                              title: Text(
                                l10n.studentAssignmentProgressAttemptLabel(
                                  t.attemptNumber,
                                  t.percentage.toStringAsFixed(0),
                                ),
                                style: TextStyle(
                                  color: _scoreColor(t.percentage),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Icon(
                                data.canViewDetailedReview
                                    ? Icons.chevron_right_rounded
                                    : Icons.lock_outline_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (data.canViewDetailedReview &&
                          data.hardQuestionsForMe.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppSectionTitle(
                          title: l10n
                              .studentAssignmentProgressHardQuestionsTitle,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...data.hardQuestionsForMe.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppSectionCard(
                              child: Text(
                                q.questionText,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
