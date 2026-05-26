import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_class_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_class_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_class_detail_page.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_create_class_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TeacherClassListPage extends StatefulWidget {
  const TeacherClassListPage({super.key});

  @override
  State<TeacherClassListPage> createState() => _TeacherClassListPageState();
}

class _TeacherClassListPageState extends State<TeacherClassListPage> {
  final _repo = getIt<TeacherClassRepository>();
  late Future<List<TeacherClassSummaryModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final future = _repo.listClasses();
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
      body: FutureBuilder<List<TeacherClassSummaryModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: snapshot.error.toString(),
              onRetry: _load,
              retryLabel: l10n.retry,
            );
          }
          final classes = snapshot.data!;
          if (classes.isEmpty) {
            return AppEmptyView(
              message: l10n.teacherClassesEmpty,
              icon: Icons.class_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.teacherAccent,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ClassTile(
                cls: classes[i],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TeacherClassDetailPage(classId: classes[i].classId)),
                  );
                  _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.cls, required this.onTap});

  final TeacherClassSummaryModel cls;
  final VoidCallback onTap;

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
            color: AppColors.teacherAccent.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teacherAccentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.class_rounded,
                  color: AppColors.teacherAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
                      if (cls.pendingMemberCount > 0) ...[
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
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
