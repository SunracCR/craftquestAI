import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/member_avatar.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/analytics/presentation/question_distractor_card.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_assignment_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TeacherAssignmentAnalyticsPage extends StatefulWidget {
  const TeacherAssignmentAnalyticsPage({
    super.key,
    required this.assignmentId,
    required this.quizTitle,
    this.showAppBar = true,
  });

  final String assignmentId;
  final String quizTitle;
  final bool showAppBar;

  @override
  State<TeacherAssignmentAnalyticsPage> createState() =>
      _TeacherAssignmentAnalyticsPageState();
}

class _TeacherAssignmentAnalyticsPageState
    extends State<TeacherAssignmentAnalyticsPage> {
  final _repo = getIt<TeacherAssignmentRepository>();
  late Future<AssignmentAnalyticsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getAssignmentAnalytics(widget.assignmentId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.getAssignmentAnalytics(widget.assignmentId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final content = FutureBuilder<AssignmentAnalyticsModel>(
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
          return AppPaddedScrollBody(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
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
                          data.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.className,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppStatusChip(
                              label: l10n.teacherAssignmentAnalyticsCompletionLabel(
                                data.uniqueStudentsCompleted,
                                data.totalMembers,
                              ),
                              color: AppColors.teacherAccent,
                            ),
                            AppStatusChip(
                              label:
                                  '${l10n.teacherClassAnalyticsAverageLabel}: ${data.averageScore.toStringAsFixed(1)}%',
                              color: AppColors.accentGold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      AppSectionTitle(
                        title: l10n.teacherAssignmentAnalyticsRosterTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...data.students.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StudentProgressCard(
                            student: s,
                            l10n: l10n,
                            quizTitle: widget.quizTitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSectionTitle(
                        title: l10n
                            .teacherAssignmentAnalyticsDistributionTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ScoreDistributionCard(
                        buckets: data.scoreDistribution,
                        l10n: l10n,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSectionTitle(
                        title: l10n
                            .teacherAssignmentAnalyticsHardQuestionsTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (data.hardQuestions.isEmpty)
                        Text(
                          l10n.teacherDashboardEmptyInsights,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      else
                        ...data.hardQuestions.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.questionText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.teacherAssignmentAnalyticsErrorRateLabel(
                                      q.errorRate.toStringAsFixed(0),
                                      q.attemptsCount,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSectionTitle(
                        title: l10n
                            .teacherAssignmentAnalyticsDistractorTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (data.distractorQuestions.isEmpty)
                        Text(
                          l10n.teacherDashboardEmptyInsights,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      else
                        ...data.distractorQuestions.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppSectionCard(
                              child: QuestionDistractorCard(
                                question: q,
                                l10n: l10n,
                              ),
                            ),
                          ),
                        ),
                    ],
                ),
              ],
              ),
            ),
          );
        },
    );

    if (!widget.showAppBar) {
      return content;
    }

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.teacherAssignmentAnalyticsTitle),
      body: content,
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  const _StudentProgressCard({
    required this.student,
    required this.l10n,
    required this.quizTitle,
  });

  final AssignmentStudentProgressModel student;
  final AppLocalizations l10n;
  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    final accent = student.hasCompleted
        ? (student.bestScore != null && student.bestScore! >= 70
            ? AppColors.accentMint
            : AppColors.accentGold)
        : AppColors.warning;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: student.lastPracticeSessionId != null
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TeacherSessionReviewPage(
                      sessionId: student.lastPracticeSessionId!,
                      quizTitle: quizTitle,
                    ),
                  ),
                );
              }
            : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppColors.radiusSm),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MemberAvatar(
                            avatarId: student.avatarId,
                            displayName: student.displayName,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              student.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (!student.hasCompleted)
                        Text(
                          l10n.teacherAssignmentAnalyticsNoAttempt,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else ...[
                        if (student.bestScore != null)
                          Text(
                            l10n.teacherAssignmentAnalyticsBestLabel(
                              student.bestScore!.toStringAsFixed(0),
                            ),
                            style: const TextStyle(
                              color: AppColors.accentMint,
                              fontSize: 12,
                            ),
                          ),
                        if (student.lastScore != null)
                          Text(
                            l10n.teacherAssignmentAnalyticsLastLabel(
                              student.lastScore!.toStringAsFixed(0),
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
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
    );
  }
}

class _ScoreDistributionCard extends StatelessWidget {
  const _ScoreDistributionCard({
    required this.buckets,
    required this.l10n,
  });

  final List<ScoreDistributionBucketModel> buckets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final maxCount = buckets
        .map((b) => b.studentCount)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return AppSectionCard(
      child: Column(
        children: [
          for (var i = 0; i < buckets.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _DistributionBar(
              bucket: buckets[i],
              l10n: l10n,
              maxCount: maxCount,
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.bucket,
    required this.l10n,
    required this.maxCount,
  });

  final ScoreDistributionBucketModel bucket;
  final AppLocalizations l10n;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final value = maxCount == 0 ? 0.0 : bucket.studentCount / maxCount;
    final color = bucket.minPercent >= 61
        ? AppColors.accentMint
        : bucket.minPercent >= 41
            ? AppColors.accentGold
            : AppColors.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            l10n.scoreDistributionRange(bucket.minPercent, bucket.maxPercent),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.background,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 28,
          child: Text(
            '${bucket.studentCount}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
