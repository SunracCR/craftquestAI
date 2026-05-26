import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/practice/presentation/practice_navigation.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';
import 'package:craftquest_app/features/student/presentation/student_assignment_attempts_page.dart';
import 'package:craftquest_app/features/student/presentation/student_assignment_progress_page.dart';
import 'package:craftquest_app/features/student/presentation/student_assignment_list_logic.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class StudentAssignmentDetailPage extends StatelessWidget {
  const StudentAssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.onChanged,
  });

  final StudentAssignmentModel assignment;
  final VoidCallback onChanged;

  String _formatDate(String locale, DateTime date) =>
      AssignmentDates.formatWithLocale(locale, date);

  String _startsChipLabel(AppLocalizations l10n, String locale) {
    if (assignment.startsAt == null) {
      return l10n.studentAssignmentAvailableNowLabel;
    }
    return '${l10n.teacherAssignmentStartsAtLabel}: ${_formatDate(locale, assignment.startsAt!)}';
  }

  String _dueChipLabel(AppLocalizations l10n, String locale) {
    if (assignment.dueAt == null) {
      return l10n.teacherAssignmentNoDueDate;
    }
    return '${l10n.teacherAssignmentDueLabel}: ${_formatDate(locale, assignment.dueAt!)}';
  }

  String _statusLabel(AppLocalizations l10n) =>
      StudentAssignmentListLogic.statusLabel(l10n, assignment);

  Future<void> _start(BuildContext context) async {
    if (!assignment.isOpen) return;
    await openPracticeSession(
      context,
      quizId: assignment.quizId,
      quizTitle: assignment.title,
      classId: assignment.classId,
      assignmentId: assignment.assignmentId,
    );
    onChanged();
  }

  void _openMyAttempts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentAssignmentAttemptsPage(
          assignmentId: assignment.assignmentId,
          assignmentTitle: assignment.title,
          quizTitle: assignment.quizTitle,
        ),
      ),
    );
  }

  void _openMyProgress(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentAssignmentProgressPage(
          assignmentId: assignment.assignmentId,
          quizTitle: assignment.quizTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final status = StudentAssignmentListLogic.visualStatus(assignment);
    final accent = StudentAssignmentListLogic.accentForStatus(status);
    final canStart = assignment.isOpen;
    final canViewAttempts = assignment.myAttemptCount > 0;

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.studentAssignmentDetailTitle),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppSectionCard(
            padding: EdgeInsets.zero,
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    StudentAssignmentListLogic.iconForStatus(
                                      status,
                                    ),
                                    color: accent,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (assignment.quizTitle !=
                                        assignment.title) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        assignment.quizTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _MetaLine(
                            icon: Icons.class_rounded,
                            label: assignment.className,
                          ),
                          const SizedBox(height: 4),
                          _MetaLine(
                            icon: Icons.person_outline_rounded,
                            label: assignment.teacherDisplayName,
                          ),
                          if (assignment.instructions?.trim().isNotEmpty ??
                              false) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              assignment.instructions!.trim(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _InfoChip(
                                icon: Icons.event_rounded,
                                label: _startsChipLabel(l10n, locale),
                                color: assignment.isNotYetOpen
                                    ? AppColors.accentGold
                                    : AppColors.textSecondary,
                              ),
                              _InfoChip(
                                icon: Icons.event_busy_rounded,
                                label: _dueChipLabel(l10n, locale),
                                color: assignment.isPastDue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              if (assignment.maxAttempts != null)
                                _InfoChip(
                                  icon: Icons.replay_rounded,
                                  label: l10n.studentAssignmentAttemptsSummary(
                                    assignment.myAttemptCount,
                                    assignment.maxAttempts!,
                                  ),
                                  color: assignment.hasReachedMaxAttempts
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (canStart)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  ),
                ),
                onPressed: () => _start(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  l10n.studentAssignmentStartAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(
                _statusLabel(l10n),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: status == StudentAssignmentVisualStatus.notYetOpen
                          ? AppColors.accentGold
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          if (canViewAttempts) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: accent.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  ),
                ),
                onPressed: () => _openMyProgress(context),
                icon: const Icon(Icons.insights_outlined, size: 22),
                label: Text(
                  l10n.studentAssignmentProgressAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: accent.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  ),
                ),
                onPressed: () => _openMyAttempts(context),
                icon: const Icon(Icons.history_rounded, size: 22),
                label: Text(
                  l10n.studentAssignmentMyAttemptsAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
