import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/features/student/data/models/student_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum StudentAssignmentVisualStatus {
  available,
  notYetOpen,
  pastDue,
  closed,
  maxAttempts,
  unavailable,
}

class StudentAssignmentClassGroup {
  const StudentAssignmentClassGroup({
    required this.classId,
    required this.className,
    required this.teacherDisplayName,
    required this.assignments,
  });

  final String classId;
  final String className;
  final String teacherDisplayName;
  final List<StudentAssignmentModel> assignments;
}

class StudentAssignmentsSummary {
  const StudentAssignmentsSummary({
    required this.openCount,
    required this.dueTodayCount,
  });

  final int openCount;
  final int dueTodayCount;
}

abstract final class StudentAssignmentListLogic {
  static bool isDueToday(DateTime? dueAt) {
    if (dueAt == null) return false;
    return AssignmentDates.calendarDate(dueAt) == AssignmentDates.todayLocal();
  }

  static StudentAssignmentVisualStatus visualStatus(
    StudentAssignmentModel assignment,
  ) {
    if (assignment.isNotYetOpen) {
      return StudentAssignmentVisualStatus.notYetOpen;
    }
    if (assignment.status == 'closed') {
      return StudentAssignmentVisualStatus.closed;
    }
    if (assignment.isPastDue) {
      return StudentAssignmentVisualStatus.pastDue;
    }
    if (assignment.hasReachedMaxAttempts) {
      return StudentAssignmentVisualStatus.maxAttempts;
    }
    if (assignment.isOpen) {
      return StudentAssignmentVisualStatus.available;
    }
    return StudentAssignmentVisualStatus.unavailable;
  }

  static Color accentForStatus(StudentAssignmentVisualStatus status) {
    return switch (status) {
      StudentAssignmentVisualStatus.available => AppColors.accentMint,
      StudentAssignmentVisualStatus.notYetOpen => AppColors.accentGold,
      StudentAssignmentVisualStatus.pastDue ||
      StudentAssignmentVisualStatus.maxAttempts =>
        AppColors.error,
      StudentAssignmentVisualStatus.closed ||
      StudentAssignmentVisualStatus.unavailable =>
        AppColors.textSecondary,
    };
  }

  static IconData iconForStatus(StudentAssignmentVisualStatus status) {
    return switch (status) {
      StudentAssignmentVisualStatus.available => Icons.play_circle_outline_rounded,
      StudentAssignmentVisualStatus.notYetOpen => Icons.schedule_rounded,
      StudentAssignmentVisualStatus.pastDue => Icons.event_busy_rounded,
      StudentAssignmentVisualStatus.maxAttempts => Icons.block_rounded,
      StudentAssignmentVisualStatus.closed => Icons.lock_outline_rounded,
      StudentAssignmentVisualStatus.unavailable => Icons.info_outline_rounded,
    };
  }

  static int _sortPriority(StudentAssignmentModel assignment) {
    final status = visualStatus(assignment);
    return switch (status) {
      StudentAssignmentVisualStatus.available => 0,
      StudentAssignmentVisualStatus.notYetOpen => 1,
      StudentAssignmentVisualStatus.maxAttempts => 2,
      StudentAssignmentVisualStatus.pastDue => 3,
      StudentAssignmentVisualStatus.closed => 4,
      StudentAssignmentVisualStatus.unavailable => 5,
    };
  }

  static int compareAssignments(
    StudentAssignmentModel a,
    StudentAssignmentModel b,
  ) {
    final priorityDiff = _sortPriority(a).compareTo(_sortPriority(b));
    if (priorityDiff != 0) return priorityDiff;

    if (a.isOpen && b.isOpen) {
      final aDue = a.dueAt;
      final bDue = b.dueAt;
      if (aDue != null && bDue != null) {
        return aDue.compareTo(bDue);
      }
      if (aDue != null) return -1;
      if (bDue != null) return 1;
    }

    final aDate = a.dueAt ?? a.startsAt ?? a.createdAt;
    final bDate = b.dueAt ?? b.startsAt ?? b.createdAt;
    return bDate.compareTo(aDate);
  }

  static List<StudentAssignmentModel> sortAssignments(
    List<StudentAssignmentModel> assignments,
  ) {
    final sorted = List<StudentAssignmentModel>.from(assignments)
      ..sort(compareAssignments);
    return sorted;
  }

  static StudentAssignmentsSummary buildSummary(
    List<StudentAssignmentModel> assignments,
  ) {
    var openCount = 0;
    var dueTodayCount = 0;
    for (final assignment in assignments) {
      if (assignment.isOpen) {
        openCount++;
        if (isDueToday(assignment.dueAt)) {
          dueTodayCount++;
        }
      }
    }
    return StudentAssignmentsSummary(
      openCount: openCount,
      dueTodayCount: dueTodayCount,
    );
  }

  static List<StudentAssignmentModel> applyFilters({
    required List<StudentAssignmentModel> assignments,
    required String? selectedClassId,
    required bool pendingOnly,
    required String searchQuery,
  }) {
    final query = searchQuery.trim().toLowerCase();
    return assignments.where((assignment) {
      if (selectedClassId != null && assignment.classId != selectedClassId) {
        return false;
      }
      if (pendingOnly && !assignment.isOpen) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        assignment.title,
        assignment.quizTitle,
        assignment.className,
        assignment.teacherDisplayName,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  static List<StudentAssignmentClassGroup> groupByClass(
    List<StudentAssignmentModel> assignments,
  ) {
    final byClass = <String, List<StudentAssignmentModel>>{};
    for (final assignment in assignments) {
      byClass.putIfAbsent(assignment.classId, () => []).add(assignment);
    }

    return byClass.entries
        .map((entry) {
          final sorted = sortAssignments(entry.value);
          return StudentAssignmentClassGroup(
            classId: entry.key,
            className: sorted.first.className,
            teacherDisplayName: sorted.first.teacherDisplayName,
            assignments: sorted,
          );
        })
        .toList()
      ..sort((a, b) => a.className.compareTo(b.className));
  }

  static String attemptsSuffix(
    AppLocalizations l10n,
    StudentAssignmentModel assignment,
  ) {
    final max = assignment.maxAttempts;
    if (max == null) return '';
    return l10n.studentAssignmentAttemptsSuffix(
      l10n.studentAssignmentAttemptsSummary(
        assignment.myAttemptCount,
        max,
      ),
    );
  }

  static String statusLabel(
    AppLocalizations l10n,
    StudentAssignmentModel assignment,
  ) {
    return switch (visualStatus(assignment)) {
      StudentAssignmentVisualStatus.notYetOpen =>
        l10n.studentAssignmentNotYetOpenLabel,
      StudentAssignmentVisualStatus.closed => l10n.studentAssignmentClosedLabel,
      StudentAssignmentVisualStatus.pastDue =>
        l10n.studentAssignmentPastDueLabel,
      StudentAssignmentVisualStatus.maxAttempts =>
        l10n.studentAssignmentMaxAttemptsLabel,
      StudentAssignmentVisualStatus.available =>
        l10n.studentAssignmentStatusBadgeAvailable,
      StudentAssignmentVisualStatus.unavailable =>
        l10n.studentAssignmentUnavailableLabel,
    };
  }

  static String rowSubtitle(
    AppLocalizations l10n,
    String locale,
    StudentAssignmentModel assignment,
  ) {
    final suffix = attemptsSuffix(l10n, assignment);
    final status = visualStatus(assignment);

    if (status == StudentAssignmentVisualStatus.notYetOpen) {
      final startsAt = assignment.startsAt;
      if (startsAt == null) {
        return l10n.studentAssignmentNotYetOpenLabel;
      }
      return l10n.studentAssignmentRowSubtitleNotYetOpen(
        AssignmentDates.formatWithLocale(locale, startsAt),
      );
    }

    if (status == StudentAssignmentVisualStatus.available) {
      final dueAt = assignment.dueAt;
      if (dueAt == null) {
        return l10n.studentAssignmentRowSubtitleNoDue(suffix);
      }
      if (isDueToday(dueAt)) {
        return l10n.studentAssignmentRowSubtitleDueToday(suffix);
      }
      return l10n.studentAssignmentRowSubtitleDue(
        AssignmentDates.formatWithLocale(locale, dueAt),
        suffix,
      );
    }

    return l10n.studentAssignmentRowSubtitleStatus(
      statusLabel(l10n, assignment),
      suffix,
    );
  }

  static String summaryMessage(
    AppLocalizations l10n,
    StudentAssignmentsSummary summary,
  ) {
    if (summary.openCount == 0) {
      return l10n.studentAssignmentsSummaryAllDone;
    }
    final todo = l10n.studentAssignmentsSummaryTodoOnly(summary.openCount);
    if (summary.dueTodayCount == 0) {
      return todo;
    }
    final dueToday =
        l10n.studentAssignmentsSummaryDueTodayOnly(summary.dueTodayCount);
    return l10n.studentAssignmentsSummaryCombined(todo, dueToday);
  }
}
