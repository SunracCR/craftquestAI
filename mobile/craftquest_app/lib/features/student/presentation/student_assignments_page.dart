import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/utils/deferred_screen_load.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';
import 'package:craftquest_app/features/student/data/student_repository.dart';
import 'package:craftquest_app/features/student/presentation/student_assignment_detail_page.dart';
import 'package:craftquest_app/features/student/presentation/student_assignment_list_logic.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum _StudentAssignmentsFilter { all, pending }

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage>
    with ScreenLoadGeneration {
  final _repository = getIt<StudentRepository>();
  final _searchController = TextEditingController();
  final Set<String> _expandedClassIds = {};

  List<StudentAssignmentModel> _assignments = [];
  bool _loading = true;
  String? _error;
  _StudentAssignmentsFilter _filter = _StudentAssignmentsFilter.all;
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    scheduleInitialScreenLoad(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    final loadId = beginScreenLoad();
    if (!mounted) return;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final assignments = await _repository.listMyAssignments();
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _assignments = assignments;
        _loading = false;
        if (_expandedClassIds.isEmpty) {
          final groups = StudentAssignmentListLogic.groupByClass(assignments);
          if (groups.length <= 2) {
            _expandedClassIds.addAll(groups.map((g) => g.classId));
          } else {
            _expandedClassIds.addAll(
              groups
                  .where((g) => g.assignments.any((a) => a.isOpen))
                  .map((g) => g.classId),
            );
          }
        }
      });
    } on DioException catch (e) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.map(e, AppLocalizations.of(context));
        _loading = false;
      });
    } catch (_) {
      if (!mounted || isStaleScreenLoad(loadId)) return;
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  List<StudentAssignmentModel> get _filteredAssignments {
    return StudentAssignmentListLogic.applyFilters(
      assignments: _assignments,
      selectedClassId: _selectedClassId,
      pendingOnly: _filter == _StudentAssignmentsFilter.pending,
      searchQuery: _searchController.text,
    );
  }

  List<StudentAssignmentClassGroup> get _classGroups {
    return StudentAssignmentListLogic.groupByClass(_filteredAssignments);
  }

  List<StudentAssignmentClassGroup> get _allClassGroups {
    return StudentAssignmentListLogic.groupByClass(_assignments);
  }

  Future<void> _openDetail(StudentAssignmentModel assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentAssignmentDetailPage(
          assignment: assignment,
          onChanged: () => _load(showLoading: false),
        ),
      ),
    );
    if (!mounted) return;
    scheduleReturnRefresh(() => _load(showLoading: false));
  }

  void _selectFilter(_StudentAssignmentsFilter filter) {
    setState(() {
      _filter = filter;
      if (filter == _StudentAssignmentsFilter.pending) {
        _selectedClassId = null;
      }
    });
  }

  void _selectClass(String? classId) {
    setState(() {
      _selectedClassId = classId;
      if (classId != null) {
        _filter = _StudentAssignmentsFilter.all;
      }
    });
  }

  Widget _buildSummaryBanner(AppLocalizations l10n) {
    final summary =
        StudentAssignmentListLogic.buildSummary(_assignments);
    final message = StudentAssignmentListLogic.summaryMessage(l10n, summary);
    final hasUrgent = summary.dueTodayCount > 0;
    final variant = hasUrgent
        ? AppNoticeVariant.warning
        : summary.openCount > 0
            ? AppNoticeVariant.success
            : AppNoticeVariant.info;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: AppNoticeBanner(
        message: message,
        variant: variant,
        icon: hasUrgent
            ? Icons.notifications_active_outlined
            : summary.openCount > 0
                ? Icons.assignment_turned_in_outlined
                : Icons.info_outline_rounded,
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    final borderColor = AppColors.textSecondary.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
        cursorColor: AppColors.accentCool,
        decoration: InputDecoration(
          hintText: l10n.studentAssignmentsSearchHint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceHighlight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            borderSide: BorderSide(
              color: AppColors.accentCool.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final classGroups = _allClassGroups;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _FilterChip(
            label: l10n.studentAssignmentsFilterAll,
            selected: _filter == _StudentAssignmentsFilter.all &&
                _selectedClassId == null,
            onTap: () {
              setState(() {
                _filter = _StudentAssignmentsFilter.all;
                _selectedClassId = null;
              });
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: l10n.studentAssignmentsFilterPending,
            selected: _filter == _StudentAssignmentsFilter.pending,
            onTap: () => _selectFilter(_StudentAssignmentsFilter.pending),
          ),
          for (final group in classGroups) ...[
            const SizedBox(width: AppSpacing.xs),
            _FilterChip(
              label: group.className,
              selected: _selectedClassId == group.classId,
              onTap: () => _selectClass(
                _selectedClassId == group.classId ? null : group.classId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    AppLocalizations l10n,
    StudentAssignmentModel assignment,
  ) {
    final status = StudentAssignmentListLogic.visualStatus(assignment);
    final color = StudentAssignmentListLogic.accentForStatus(status);
    final label = StudentAssignmentListLogic.statusLabel(l10n, assignment);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildAssignmentRow(
    AppLocalizations l10n,
    String locale,
    StudentAssignmentModel assignment,
  ) {
    final status = StudentAssignmentListLogic.visualStatus(assignment);
    final accent = StudentAssignmentListLogic.accentForStatus(status);
    final showBadge = status != StudentAssignmentVisualStatus.available ||
        StudentAssignmentListLogic.isDueToday(assignment.dueAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppListEntryCard(
        title: assignment.title,
        subtitle: StudentAssignmentListLogic.rowSubtitle(
          l10n,
          locale,
          assignment,
        ),
        accentColor: accent,
        leadingIcon: StudentAssignmentListLogic.iconForStatus(status),
        trailing: showBadge ? _buildStatusBadge(l10n, assignment) : null,
        onTap: () => _openDetail(assignment),
      ),
    );
  }

  Widget _buildClassAccordion(
    AppLocalizations l10n,
    String locale,
    StudentAssignmentClassGroup group,
  ) {
    final expanded = _expandedClassIds.contains(group.classId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('student-class-${group.classId}'),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            setState(() {
              if (value) {
                _expandedClassIds.add(group.classId);
              } else {
                _expandedClassIds.remove(group.classId);
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.accentViolet.withValues(alpha: 0.2),
            child: Icon(
              Icons.class_rounded,
              color: AppColors.accentViolet.withValues(alpha: 0.95),
              size: 20,
            ),
          ),
          title: Text(
            group.className,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            l10n.studentAssignmentsClassGroupSubtitle(
              group.teacherDisplayName,
              group.assignments.length,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          children: group.assignments
              .map(
                (assignment) =>
                    _buildAssignmentRow(l10n, locale, assignment),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAssignmentsList(AppLocalizations l10n, String locale) {
    final filtered = StudentAssignmentListLogic.sortAssignments(
      _filteredAssignments,
    );
    final groups = _classGroups;
    final useAccordion =
        _selectedClassId == null && groups.length > 1;

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppEmptyView(
            icon: Icons.filter_list_off_rounded,
            message: l10n.studentAssignmentsEmptyFiltered,
          ),
        ],
      );
    }

    if (!useAccordion) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.listBottom,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildAssignmentRow(l10n, locale, filtered[index]),
          );
        },
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.listBottom,
      children: [
        for (final group in groups) _buildClassAccordion(l10n, locale, group),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.studentAssignmentsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      AppErrorView(
                        message: _error!,
                        onRetry: _load,
                        retryLabel: l10n.retry,
                      ),
                    ],
                  )
                : _assignments.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          AppEmptyView(
                            icon: Icons.assignment_outlined,
                            message: l10n.studentAssignmentsEmpty,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSummaryBanner(l10n),
                          _buildSearchField(l10n),
                          _buildFilterChips(l10n),
                          const SizedBox(height: AppSpacing.sm),
                          Expanded(
                            child: _buildAssignmentsList(l10n, locale),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.background : AppColors.textPrimary,
          ),
      selectedColor: AppColors.accentViolet,
      backgroundColor: AppColors.surfaceHighlight,
      side: BorderSide(
        color: selected
            ? AppColors.accentViolet
            : AppColors.textSecondary.withValues(alpha: 0.25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
