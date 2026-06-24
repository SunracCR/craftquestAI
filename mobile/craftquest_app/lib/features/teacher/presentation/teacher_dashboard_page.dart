import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_client.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_dashboard_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_assignment_detail_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/features/teacher/presentation/utils/teacher_insight_labels.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_activity_feed.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_insight_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final _repo = getIt<TeacherDashboardRepository>();
  final _billingRepo = getIt<BillingRepository>();

  late Future<TeacherDashboardModel> _future;
  bool _isExpiring = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
    _checkExpiring();
  }

  Future<void> _checkExpiring() async {
    try {
      final expiring = await _billingRepo.isSubscriptionExpiring();
      if (mounted && expiring) setState(() => _isExpiring = true);
    } catch (_) {}
  }

  void _refresh() {
    setState(() {
      _future = _loadDashboard(forceRefresh: true);
      _isExpiring = false;
    });
    _checkExpiring();
  }

  Future<TeacherDashboardModel> _loadDashboard({bool forceRefresh = false}) async {
    try {
      return await _repo.getDashboard(forceRefresh: forceRefresh);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          await getIt<ApiClient>().refreshTokens()) {
        return _repo.getDashboard(forceRefresh: true);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<TeacherDashboardModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teacherAccent),
          );
        }
        if (snapshot.hasError) {
          final message = snapshot.error is DioException
              ? DioErrorMapper.map(snapshot.error as DioException, l10n)
              : DioErrorMapper.genericMessage(l10n);
          return AppErrorView(
            onRetry: _refresh,
            message: message,
            retryLabel: l10n.retry,
          );
        }

        final data = snapshot.data!;
        return AppPaddedScrollBody(
          child: RefreshIndicator(
          color: AppColors.teacherAccent,
          onRefresh: () async => _refresh(),
          child: ListView(
            children: [
              if (_isExpiring)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppNoticeBanner(
                    message: l10n.teacherUpgradeExpiryWarning,
                    variant: AppNoticeVariant.warning,
                  ),
                ),
              _InventoryRow(data: data, l10n: l10n),
              const SizedBox(height: 20),
              _UrgentSection(data: data, l10n: l10n),
              const SizedBox(height: 20),
              _WeekSection(data: data, l10n: l10n),
              if (data.insights.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.teacherDashboardInsightsTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...data.insights.map(
                  (ins) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TeacherInsightCard(
                      insight: ins,
                      message: resolveTeacherInsightMessage(l10n, ins),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.teacherDashboardActivityFeedTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              if (data.recentActivity.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.teacherDashboardEmptyFeed,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                AppSectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TeacherActivityFeed(
                    items: data.recentActivity,
                    onTap: (item) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TeacherSessionReviewPage(
                            sessionId: item.practiceSessionId,
                            quizTitle: item.quizTitle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        );
      },
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.data, required this.l10n});

  final TeacherDashboardModel data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: l10n.teacherDashboardInventoryStudents,
            value: '${data.totalStudents}',
            color: AppColors.teacherAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: l10n.teacherDashboardInventoryClasses,
            value: '${data.activeClasses}',
            color: AppColors.accentCool,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: l10n.teacherDashboardInventoryQuizzes,
            value: '${data.assignedQuizzes}',
            color: AppColors.accentGold,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UrgentSection extends StatelessWidget {
  const _UrgentSection({required this.data, required this.l10n});

  final TeacherDashboardModel data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teacherDashboardUrgentTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (data.urgentAssignments.isEmpty)
          Text(
            l10n.teacherDashboardUrgentEmpty,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          )
        else
          ...data.urgentAssignments.map((u) {
            final dueLabel = u.dueAt != null
                ? l10n.teacherDashboardUrgentDueLabel(
                    AssignmentDates.formatWithLocale(locale, u.dueAt!),
                  )
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppSectionCard(
                variant: AppCardVariant.highlight,
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TeacherAssignmentDetailPage(
                          assignmentId: u.assignmentId,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.className,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.teacherDashboardUrgentPendingLabel(
                          u.pendingStudents,
                          u.totalMembers,
                        ),
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dueLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dueLabel,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({required this.data, required this.l10n});

  final TeacherDashboardModel data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentMint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppColors.accentMint,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.teacherDashboardActiveStudentsWeek(
                data.uniqueActiveStudentsThisWeek,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
