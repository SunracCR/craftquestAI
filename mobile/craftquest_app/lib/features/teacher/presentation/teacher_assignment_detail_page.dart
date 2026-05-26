import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/member_avatar.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_assignment_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_assignment_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_attempt_format.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_assignment_analytics_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_create_assignment_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_completion_bar.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TeacherAssignmentDetailPage extends StatefulWidget {
  const TeacherAssignmentDetailPage({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<TeacherAssignmentDetailPage> createState() =>
      _TeacherAssignmentDetailPageState();
}

class _TeacherAssignmentDetailPageState
    extends State<TeacherAssignmentDetailPage>
    with SingleTickerProviderStateMixin {
  final _repo = getIt<TeacherAssignmentRepository>();
  late TabController _tabController;
  late Future<AssignmentDetailModel> _detailFuture;
  late Future<AssignmentCompletionModel> _completionFuture;
  String? _attemptsFilterUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _detailFuture = _repo.getDetail(widget.assignmentId);
      _completionFuture = _repo.getCompletion(widget.assignmentId);
    });
  }

  void _openStudentAttempts(String? userId) {
    setState(() => _attemptsFilterUserId = userId);
    _tabController.animateTo(1);
  }

  Future<void> _edit(AssignmentDetailModel detail) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TeacherCreateAssignmentPage(
          classId: detail.classId,
          assignmentToEdit: detail,
        ),
      ),
    );
    if (updated == true && mounted) _load();
  }

  Future<void> _close(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.teacherAssignmentCloseConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.teacherAssignmentCloseConfirmMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.teacherAssignmentCloseAction,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _repo.closeAssignment(widget.assignmentId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<AssignmentDetailModel>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                backgroundColor: AppColors.background, body: AppLoadingView());
          }
          if (snap.hasError) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: AppErrorView(
                  message: snap.error.toString(),
                  onRetry: _load,
                  retryLabel: l10n.retry),
            );
          }
          final detail = snap.data!;

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                actions: [
                  IconButton(
                    tooltip: l10n.teacherAssignmentAnalyticsAction,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TeacherAssignmentAnalyticsPage(
                            assignmentId: widget.assignmentId,
                            quizTitle: detail.quizTitle,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights_outlined),
                  ),
                  if (detail.status == 'active')
                    IconButton(
                      tooltip: l10n.teacherAssignmentEditAction,
                      onPressed: () => _edit(detail),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (detail.status == 'active')
                    TextButton(
                      onPressed: () => _close(l10n),
                      child: Text(l10n.teacherAssignmentCloseAction,
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  PopupMenuButton<String>(
                    color: AppColors.surface,
                    onSelected: (v) async {
                      if (v == 'archive') {
                        await _repo.archiveAssignment(widget.assignmentId);
                        if (mounted) Navigator.pop(context, true);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(l10n.teacherAssignmentArchiveAction,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 16, bottom: 60),
                  title: Text(
                    detail.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.teacherAccent,
                  labelColor: AppColors.teacherAccent,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: l10n.teacherAssignmentCompletionTitle),
                    Tab(text: l10n.teacherAssignmentAttemptsTitle),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _CompletionTab(
                  future: _completionFuture,
                  onRetry: _load,
                  onStudentTap: _openStudentAttempts,
                ),
                _AttemptsTab(
                  attempts: detail.attempts,
                  quizTitle: detail.quizTitle,
                  filterUserId: _attemptsFilterUserId,
                  onFilterChanged: (userId) =>
                      setState(() => _attemptsFilterUserId = userId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompletionTab extends StatelessWidget {
  const _CompletionTab({
    required this.future,
    required this.onRetry,
    required this.onStudentTap,
  });

  final Future<AssignmentCompletionModel> future;
  final VoidCallback onRetry;
  final ValueChanged<String?> onStudentTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<AssignmentCompletionModel>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppLoadingView();
        }
        if (snap.hasError) {
          return AppErrorView(
              message: snap.error.toString(),
              onRetry: onRetry,
              retryLabel: l10n.retry);
        }

        final data = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TeacherCompletionBar(
              completedCount: data.completedCount,
              totalMembers: data.totalMembers,
              color: AppColors.teacherAccent,
            ),
            const SizedBox(height: 20),
            ...data.members.map((m) {
              final canViewAttempts = m.attemptCount > 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusSm),
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusSm),
                    onTap: canViewAttempts
                        ? () => onStudentTap(m.userId)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              MemberAvatar(
                                avatarId: m.avatarId,
                                displayName: m.displayName,
                                size: 32,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: m.hasCompleted
                                        ? AppColors.accentMint
                                        : AppColors.surfaceHighlight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    m.hasCompleted
                                        ? Icons.check_rounded
                                        : Icons.hourglass_empty_rounded,
                                    size: 10,
                                    color: m.hasCompleted
                                        ? AppColors.background
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.displayName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                if (m.attemptCount > 0)
                                  Text(
                                      '${m.attemptCount} ${l10n.teacherAssignmentAttemptsLabel}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                          if (m.bestScorePercent != null)
                            Text(
                              '${m.bestScorePercent}%',
                              style: TextStyle(
                                color: (m.bestScorePercent ?? 0) >= 60
                                    ? AppColors.accentMint
                                    : AppColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            )
                          else
                            Text(l10n.teacherAssignmentPendingLabel,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          if (canViewAttempts) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textSecondary, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _AssignmentAttemptGroup {
  _AssignmentAttemptGroup({
    required this.userId,
    required this.displayName,
    this.avatarId,
    required this.attempts,
  });

  final String userId;
  final String displayName;
  final String? avatarId;
  final List<AssignmentAttemptModel> attempts;

  DateTime get latestDate => attempts.first.finishedAt;
}

class _AttemptsTab extends StatefulWidget {
  const _AttemptsTab({
    required this.attempts,
    required this.quizTitle,
    this.filterUserId,
    required this.onFilterChanged,
  });

  final List<AssignmentAttemptModel> attempts;
  final String quizTitle;
  final String? filterUserId;
  final ValueChanged<String?> onFilterChanged;

  @override
  State<_AttemptsTab> createState() => _AttemptsTabState();
}

class _AttemptsTabState extends State<_AttemptsTab> {
  final Set<String> _expandedUserIds = {};

  @override
  void initState() {
    super.initState();
    _syncExpandedGroups();
  }

  @override
  void didUpdateWidget(covariant _AttemptsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attempts != widget.attempts ||
        oldWidget.filterUserId != widget.filterUserId) {
      _syncExpandedGroups();
    }
  }

  void _syncExpandedGroups() {
    final groups = _groupAttempts(widget.attempts);
    _expandedUserIds
      ..clear()
      ..addAll(
        widget.filterUserId != null
            ? [widget.filterUserId!]
            : groups.length <= 2
                ? groups.map((g) => g.userId)
                : const [],
      );
  }

  List<_AssignmentAttemptGroup> _groupAttempts(
      List<AssignmentAttemptModel> attempts) {
    final byUser = <String, List<AssignmentAttemptModel>>{};
    for (final attempt in attempts) {
      byUser.putIfAbsent(attempt.studentUserId, () => []).add(attempt);
    }
    final groups = byUser.entries.map((entry) {
      final sorted = entry.value
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
      return _AssignmentAttemptGroup(
        userId: entry.key,
        displayName: sorted.first.studentName,
        attempts: sorted,
      );
    }).toList();
    groups.sort((a, b) => b.latestDate.compareTo(a.latestDate));
    return groups;
  }

  String _attemptCountLabel(AppLocalizations l10n, int count) {
    if (count == 1) return l10n.teacherAttemptsAttemptCountOne;
    return l10n.teacherAttemptsAttemptCountMany(count);
  }

  Color _scoreColor(double obtained, double possible) {
    if (possible <= 0) return AppColors.textSecondary;
    final pct = obtained / possible;
    if (pct >= 0.7) return AppColors.accentMint;
    if (pct >= 0.4) return AppColors.accentGold;
    return AppColors.accent;
  }

  void _openReview(AssignmentAttemptModel attempt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionReviewPage(
          sessionId: attempt.practiceSessionId,
          quizTitle: widget.quizTitle,
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    AppLocalizations l10n,
    List<_AssignmentAttemptGroup> groups,
  ) {
    if (groups.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: DropdownButtonFormField<String?>(
        key: ValueKey('assignment-attempts-filter-${widget.filterUserId}'),
        initialValue: widget.filterUserId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.teacherAttemptsFilterLabel,
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(l10n.teacherAttemptsFilterAll),
          ),
          for (final group in groups)
            DropdownMenuItem<String?>(
              value: group.userId,
              child: Text(group.displayName),
            ),
        ],
        onChanged: widget.onFilterChanged,
      ),
    );
  }

  Widget _buildAttemptCard(
    AppLocalizations l10n,
    AssignmentAttemptModel attempt,
  ) {
    final pct = attempt.scorePossible > 0
        ? (attempt.scoreObtained / attempt.scorePossible * 100)
            .toStringAsFixed(0)
        : '0';
    final accent = _scoreColor(attempt.scoreObtained, attempt.scorePossible);

    return AppListEntryCard(
      title: l10n.teacherAttemptTitle(
        attempt.studentName,
        formatTeacherAttemptDate(context, attempt.finishedAt),
      ),
      subtitle: buildTeacherAttemptSubtitle(
        l10n,
        obtained: attempt.scoreObtained,
        possible: attempt.scorePossible,
        percent: pct,
        status: 'finished',
        durationSeconds: null,
        showElapsedTimer: false,
      ),
      accentColor: accent,
      leadingIcon: Icons.assignment_outlined,
      onTap: () => _openReview(attempt),
    );
  }

  Widget _buildStudentAccordion(
    AppLocalizations l10n,
    _AssignmentAttemptGroup group,
  ) {
    final latestLabel =
        formatTeacherAttemptDate(context, group.latestDate);

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey('assignment-attempts-${group.userId}'),
        initiallyExpanded: _expandedUserIds.contains(group.userId),
        onExpansionChanged: (isExpanded) {
          setState(() {
            if (isExpanded) {
              _expandedUserIds.add(group.userId);
            } else {
              _expandedUserIds.remove(group.userId);
            }
          });
        },
        leading: MemberAvatar(
          avatarId: group.avatarId,
          displayName: group.displayName,
          size: 36,
        ),
        title: Text(
          group.displayName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${_attemptCountLabel(l10n, group.attempts.length)} · $latestLabel',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        children: [
          for (final attempt in group.attempts)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: _buildAttemptCard(l10n, attempt),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.attempts.isEmpty) {
      return AppEmptyView(
        message: l10n.teacherAttemptsEmpty,
        icon: Icons.assignment_outlined,
      );
    }

    final groups = _groupAttempts(widget.attempts);
    final visibleGroups = widget.filterUserId == null
        ? groups
        : groups.where((g) => g.userId == widget.filterUserId).toList();

    if (visibleGroups.isEmpty) {
      return AppEmptyView(
        message: l10n.teacherAttemptsFilterEmpty,
        icon: Icons.assignment_outlined,
      );
    }

    if (visibleGroups.length == 1 && visibleGroups.first.attempts.length == 1) {
      return ListView(
        padding: AppSpacing.listBottom,
        children: [
          _buildFilterBar(l10n, groups),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildAttemptCard(l10n, visibleGroups.first.attempts.first),
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.listBottom,
      children: [
        _buildFilterBar(l10n, groups),
        for (var i = 0; i < visibleGroups.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: visibleGroups[i].attempts.length == 1
                ? _buildAttemptCard(l10n, visibleGroups[i].attempts.first)
                : _buildStudentAccordion(l10n, visibleGroups[i]),
          ),
        ],
      ],
    );
  }
}
