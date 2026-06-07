import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_class_detail_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_create_class_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

typedef _ClassLists = ({
  List<TeacherClassSummaryModel> active,
  List<TeacherClassSummaryModel> archived,
});

class TeacherClassListPage extends StatefulWidget {
  const TeacherClassListPage({super.key});

  @override
  State<TeacherClassListPage> createState() => _TeacherClassListPageState();
}

class _TeacherClassListPageState extends State<TeacherClassListPage> {
  final _repo = getIt<TeacherClassRepository>();
  late Future<_ClassLists> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final future = _repo.listClasses(status: 'all').then((all) {
      final active = all.where((c) => c.status == 'active').toList();
      final archived = all.where((c) => c.status == 'archived').toList();
      return (active: active, archived: archived);
    });
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TeacherCreateClassPage()),
    );
    if (created == true) _load();
  }

  Future<void> _confirmRestore(
    BuildContext context,
    TeacherClassSummaryModel cls,
  ) async {
    final l10n = AppLocalizations.of(context)!;
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
      await _repo.restoreClass(cls.classId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.teacherClassRestoredMessage);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.map(e, l10n));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeacherClassSummaryModel cls,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.teacherClassDeletePermanentTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.teacherClassDeletePermanentMessage(cls.name),
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
      await _repo.deleteClass(cls.classId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.teacherClassDeletedMessage);
      await _load();
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.teacherClassesTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teacherAccent,
                foregroundColor: AppColors.textPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.teacherClassCreateAction),
              onPressed: _openCreate,
            ),
          ),
        ],
      ),
      body: FutureBuilder<_ClassLists>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: DioErrorMapper.mapAny(snapshot.error!, l10n),
              onRetry: _load,
              retryLabel: l10n.retry,
            );
          }
          final data = snapshot.data!;
          if (data.active.isEmpty && data.archived.isEmpty) {
            return AppEmptyView(
              message: l10n.teacherClassesEmpty,
              icon: Icons.class_outlined,
            );
          }
          return AppPaddedScrollBody(
            child: RefreshIndicator(
            color: AppColors.teacherAccent,
            onRefresh: _load,
            child: ListView(
              children: [
                for (var i = 0; i < data.active.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ClassTile(
                    cls: data.active[i],
                    archived: false,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherClassDetailPage(
                            classId: data.active[i].classId,
                          ),
                        ),
                      );
                      _load();
                    },
                  ),
                ],
                if (data.archived.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.teacherClassesArchivedSectionTitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < data.archived.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ClassTile(
                      cls: data.archived[i],
                      archived: true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherClassDetailPage(
                              classId: data.archived[i].classId,
                            ),
                          ),
                        );
                        _load();
                      },
                      onRestore: () => _confirmRestore(context, data.archived[i]),
                      onDelete: () => _confirmDelete(context, data.archived[i]),
                    ),
                  ],
                ],
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.cls,
    required this.archived,
    required this.onTap,
    this.onRestore,
    this.onDelete,
  });

  final TeacherClassSummaryModel cls;
  final bool archived;
  final VoidCallback onTap;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(
            color: archived
                ? AppColors.textSecondary.withOpacity(0.2)
                : AppColors.teacherAccent.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: archived
                    ? AppColors.textSecondary.withOpacity(0.12)
                    : AppColors.teacherAccentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                archived ? Icons.inventory_2_outlined : Icons.class_rounded,
                color: archived
                    ? AppColors.textSecondary
                    : AppColors.teacherAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: TextStyle(
                      color: archived
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${cls.activeMemberCount} ${l10n.teacherClassActiveMembersLabel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (!archived && cls.pendingMemberCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${cls.pendingMemberCount} ${l10n.teacherClassPendingMembersLabel}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onRestore != null)
              IconButton(
                tooltip: l10n.teacherClassRestoreAction,
                icon: const Icon(Icons.unarchive_outlined,
                    color: AppColors.accentMint, size: 22),
                onPressed: onRestore,
              ),
            if (onDelete != null)
              IconButton(
                tooltip: l10n.teacherClassDeletePermanentAction,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 22),
                onPressed: onDelete,
              ),
            if (!archived)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
