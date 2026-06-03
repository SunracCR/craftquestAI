import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/email_utils.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/member_avatar.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/features/teacher/data/teacher_dashboard_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_create_assignment_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_create_class_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_assignment_analytics_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_assignment_detail_page.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_dashboard_models.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_class_ring.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_completion_bar.dart';
import 'package:craftquest_app/features/teacher/presentation/widgets/teacher_detail_sliver_header.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TeacherClassDetailPage extends StatefulWidget {
  const TeacherClassDetailPage({super.key, required this.classId});

  final String classId;

  @override
  State<TeacherClassDetailPage> createState() => _TeacherClassDetailPageState();
}

class _TeacherClassDetailPageState extends State<TeacherClassDetailPage>
    with SingleTickerProviderStateMixin {
  final _classRepo = getIt<TeacherClassRepository>();

  late TabController _tabController;
  late Future<ClassDetailModel> _detailFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = _classRepo.getClassDetail(widget.classId);
    setState(() {
      _detailFuture = future;
    });
    await future;
  }

  Future<void> _archive(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.teacherClassArchiveConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.teacherClassArchiveConfirmMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.teacherClassArchiveConfirmAction,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _classRepo.archiveClass(widget.classId);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _restore(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.teacherClassRestoreConfirmTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.teacherClassRestoreConfirmMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.teacherClassRestoreConfirmAction,
              style: const TextStyle(color: AppColors.accentMint),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _classRepo.restoreClass(widget.classId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.teacherClassRestoredMessage);
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.map(e, l10n));
    }
  }

  Future<void> _deletePermanently(
    AppLocalizations l10n,
    String className,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.teacherClassDeletePermanentTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.teacherClassDeletePermanentMessage(className),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.teacherClassDeletePermanentConfirm,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _classRepo.deleteClass(widget.classId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.teacherClassDeletedMessage);
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.map(e, l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ClassDetailModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: AppLoadingView(),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: AppErrorView(
                message: snapshot.error.toString(),
                onRetry: _load,
                retryLabel: l10n.retry,
              ),
            );
          }

          final detail = snapshot.data!;
          final isArchived = detail.status == 'archived';
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              TeacherDetailTabbedAppBar(
                title: detail.name,
                actions: [
                  if (!isArchived)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final edited = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherCreateClassPage(
                              classId: detail.classId,
                              initialName: detail.name,
                              initialDescription: detail.description,
                            ),
                          ),
                        );
                        if (edited == true) _load();
                      },
                    ),
                  PopupMenuButton<String>(
                    color: AppColors.surface,
                    onSelected: (v) {
                      if (v == 'archive') _archive(l10n);
                      if (v == 'restore') _restore(l10n);
                      if (v == 'delete') {
                        _deletePermanently(l10n, detail.name);
                      }
                    },
                    itemBuilder: (_) => [
                      if (isArchived) ...[
                        PopupMenuItem(
                          value: 'restore',
                          child: Text(
                            l10n.teacherClassRestoreAction,
                            style: const TextStyle(
                              color: AppColors.accentMint,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            l10n.teacherClassDeletePermanentAction,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ] else
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(
                            l10n.teacherClassArchiveAction,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.teacherAccent,
                  labelColor: AppColors.teacherAccent,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: l10n.teacherClassMembersTab),
                    Tab(text: l10n.teacherClassAssignmentsTab),
                    Tab(text: l10n.teacherClassAnalyticsTab),
                  ],
                ),
              ),
              if (isArchived)
                SliverToBoxAdapter(
                  child: TeacherDetailNoticeBanner(
                    message: l10n.teacherClassArchivedBanner,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  classId: widget.classId,
                  detail: detail,
                  readOnly: isArchived,
                  onChanged: _load,
                ),
                _AssignmentsTab(
                  classId: widget.classId,
                  detail: detail,
                  readOnly: isArchived,
                  onChanged: _load,
                ),
                _AnalyticsTab(classId: widget.classId),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Members Tab ──────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  const _MembersTab({
    required this.classId,
    required this.detail,
    required this.readOnly,
    required this.onChanged,
  });

  final String classId;
  final ClassDetailModel detail;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _repo = getIt<TeacherClassRepository>();
  final _emailCtrl = TextEditingController();
  bool _addLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    if (!EmailUtils.isValid(email)) {
      context.showErrorSnackBar(l10n.teacherClassInvalidEmailError);
      return;
    }
    setState(() => _addLoading = true);
    try {
      await _repo.addMemberByEmail(classId: widget.classId, email: email);
      _emailCtrl.clear();
      widget.onChanged();
    } on DioException catch (e) {
      if (mounted) context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _addLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = widget.detail.members.where((m) => m.status == 'pending').toList();
    final active = widget.detail.members.where((m) => m.status == 'active').toList();

    return AppPaddedScrollBody(
      includeTop: false,
      child: ListView(
      children: [
        if (!widget.readOnly)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.teacherClassAddMemberEmailHint,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teacherAccent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _addLoading ? null : _addMember,
                child: _addLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                    : Text(l10n.teacherClassAddMemberAction, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeader(l10n.teacherClassPendingApprovalsTitle, badge: pending.length),
          const SizedBox(height: 8),
          ...pending.map((m) => _MemberTile(
                member: m,
                classId: widget.classId,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
              )),
        ],
        SizedBox(height: widget.readOnly ? 0 : 20),
        _sectionHeader('${l10n.teacherClassMembersTab} (${active.length})'),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.teacherClassMembersEmpty,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...active.map((m) => _MemberTile(
                member: m,
                classId: widget.classId,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
              )),
      ],
      ),
    );
  }

  Widget _sectionHeader(String text, {int? badge}) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$badge',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
        ],
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.classId,
    required this.readOnly,
    required this.onChanged,
  });

  final ClassMemberModel member;
  final String classId;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = getIt<TeacherClassRepository>();
    final isPending = member.status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        child: Row(
          children: [
            MemberAvatar(
              avatarId: member.avatarId,
              displayName: member.displayName,
              size: 36,
              accentColor: isPending ? AppColors.warning : AppColors.teacherAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.displayName,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(member.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (!readOnly)
              if (isPending)
                TextButton(
                  onPressed: () async {
                    await repo.approveMember(classId: classId, userId: member.userId);
                    onChanged();
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.accentMint),
                  child: Text(l10n.teacherClassApproveAction),
                )
              else
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () async {
                    await repo.removeMember(classId: classId, userId: member.userId);
                    onChanged();
                  },
                ),
          ],
        ),
      ),
    );
  }
}

// ─── Assignments Tab ─────────────────────────────────────────────────────────

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.classId,
    required this.detail,
    required this.readOnly,
    required this.onChanged,
  });

  final String classId;
  final ClassDetailModel detail;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPaddedScrollBody(
      includeTop: false,
      child: ListView(
      children: [
        if (!readOnly) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teacherAccent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.teacherAssignmentCreateTitle),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => TeacherCreateAssignmentPage(classId: classId)),
              );
              if (created == true) onChanged();
            },
          ),
          const SizedBox(height: 16),
        ],
        if (detail.assignments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(l10n.teacherAssignmentEmpty,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          )
        else
          ...detail.assignments.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TeacherAssignmentDetailPage(assignmentId: a.assignmentId)));
                    onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.title,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                            _statusBadge(a.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(a.quizTitle,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 10),
                        TeacherCompletionBar(
                          completedCount: a.completedCount,
                          totalMembers: a.totalMembers,
                        ),
                        if (a.dueAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${l10n.teacherAssignmentDueLabel}: ${AssignmentDates.format(context, a.dueAt!)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )),
      ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'active' => (AppColors.accentMint, 'Activa'),
      'closed' => (AppColors.accentGold, 'Cerrada'),
      _ => (AppColors.textSecondary, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

}

// ─── Analytics Tab ────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab({required this.classId});

  final String classId;

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  final _repo = getIt<TeacherDashboardRepository>();
  late Future<ClassAnalyticsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getClassAnalytics(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<ClassAnalyticsModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingView();
        }
        if (snapshot.hasError) {
          return AppErrorView(
            message: DioErrorMapper.mapAny(snapshot.error!, l10n),
            onRetry: () {
              setState(() {
                _future = _repo.getClassAnalytics(widget.classId);
              });
            },
            retryLabel: l10n.retry,
          );
        }

        final data = snapshot.data!;
        final avgCompletion = data.assignments.isEmpty
            ? 0.0
            : data.assignments
                    .map((a) => a.completionRate)
                    .fold<double>(0, (s, r) => s + r) /
                data.assignments.length;

        return AppPaddedScrollBody(
          includeTop: false,
          child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TeacherClassRing(
                  value: data.averageScore / 100,
                  label: l10n.teacherClassAnalyticsAverageLabel,
                  color: data.averageScore >= 70
                      ? AppColors.accentMint
                      : AppColors.warning,
                ),
                TeacherClassRing(
                  value: avgCompletion.clamp(0.0, 1.0),
                  label: l10n.teacherClassAnalyticsActiveStudentsLabel,
                  color: AppColors.teacherAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.teacherClassAnalyticsAssignmentsTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...data.assignments.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TeacherAssignmentAnalyticsPage(
                            assignmentId: a.assignmentId,
                            quizTitle: a.title,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TeacherCompletionBar(
                          completedCount: a.completedCount,
                          totalMembers: a.totalMembers,
                          label:
                              '${l10n.teacherClassAnalyticsAverageLabel} ${a.averageScore.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          ),
        );
      },
    );
  }
}
