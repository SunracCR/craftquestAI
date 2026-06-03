import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/member_avatar.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';
import 'package:craftquest_app/features/teacher/data/teacher_review_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_attempt_format.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TeacherAttemptsPage extends StatefulWidget {
  const TeacherAttemptsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<TeacherAttemptsPage> createState() => _TeacherAttemptsPageState();
}

class _StudentAttemptGroup {
  _StudentAttemptGroup({
    required this.userId,
    required this.displayName,
    this.avatarId,
    required this.attempts,
  });

  final String userId;
  final String displayName;
  final String? avatarId;
  final List<TeacherAttemptModel> attempts;

  DateTime get latestDate => attempts.first.sortDate;
}

class _TeacherAttemptsPageState extends State<TeacherAttemptsPage> {
  final _repository = getIt<TeacherReviewRepository>();
  List<TeacherAttemptModel>? _attempts;
  bool _loading = true;
  String? _error;
  String? _filterUserId;
  final Set<String> _expandedUserIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final attempts = [
        ...await _repository.listQuizAttempts(widget.quizId),
      ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
      if (!mounted) return;
      final groups = _groupAttempts(attempts);
      setState(() {
        _attempts = attempts;
        _loading = false;
        _expandedUserIds
          ..clear()
          ..addAll(
            groups.length <= 2 ? groups.map((g) => g.userId) : const [],
          );
        if (_filterUserId != null &&
            !groups.any((g) => g.userId == _filterUserId)) {
          _filterUserId = null;
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  List<_StudentAttemptGroup> _groupAttempts(List<TeacherAttemptModel> attempts) {
    final byUser = <String, List<TeacherAttemptModel>>{};
    for (final attempt in attempts) {
      byUser.putIfAbsent(attempt.studentUserId, () => []).add(attempt);
    }
    final groups = byUser.entries.map((entry) {
      final sorted = entry.value
        ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
      final displayName =
          sorted.first.studentDisplayName ?? sorted.first.studentUserId;
      return _StudentAttemptGroup(
        userId: entry.key,
        displayName: displayName,
        avatarId: sorted.first.studentAvatarId,
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

  Widget _buildFilterBar(
    BuildContext context,
    AppLocalizations l10n,
    List<_StudentAttemptGroup> groups,
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
        key: ValueKey('attempts-filter-$_filterUserId'),
        initialValue: _filterUserId,
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
          ...groups.map(
            (g) => DropdownMenuItem<String?>(
              value: g.userId,
              child: Text(g.displayName),
            ),
          ),
        ],
        onChanged: (userId) {
          setState(() {
            _filterUserId = userId;
            if (userId != null) {
              _expandedUserIds.add(userId);
            }
          });
        },
      ),
    );
  }

  Widget _buildStudentAccordion(
    BuildContext context,
    AppLocalizations l10n,
    _StudentAttemptGroup group,
  ) {
    final expanded = _expandedUserIds.contains(group.userId);
    final latestLabel = formatTeacherAttemptDate(context, group.latestDate);

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: ValueKey('attempts-${group.userId}-$expanded'),
        initiallyExpanded: expanded,
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
              child: _buildAttemptCard(context, l10n, attempt),
            ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(
    BuildContext context,
    AppLocalizations l10n,
    TeacherAttemptModel attempt,
  ) {
    final pct = attempt.scorePossible > 0
        ? (attempt.scoreObtained / attempt.scorePossible * 100)
            .toStringAsFixed(0)
        : '0';
    final accent = _scoreColor(attempt.scoreObtained, attempt.scorePossible);

    return AppListEntryCard(
      title: l10n.teacherAttemptRowTitle(
        formatTeacherAttemptDate(context, attempt.sortDate),
      ),
      subtitle: buildTeacherAttemptSubtitle(
        l10n,
        obtained: attempt.scoreObtained,
        possible: attempt.scorePossible,
        percent: pct,
        status: attempt.status,
        durationSeconds: attempt.durationSeconds,
        showElapsedTimer: attempt.showElapsedTimer,
      ),
      accentColor: accent,
      leadingIcon: Icons.assignment_outlined,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TeacherSessionReviewPage(
              sessionId: attempt.practiceSessionId,
              quizTitle: widget.quizTitle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.teacherAttemptsTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              widget.quizTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (_attempts != null && _attempts!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Builder(
                                builder: (context) {
                                  final groups = _groupAttempts(_attempts!);
                                  if (groups.length < 2) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    l10n.teacherAttemptsStudentsSummary(
                                      groups.length,
                                      _attempts!.length,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: (_attempts == null || _attempts!.isEmpty)
                          ? AppEmptyView(message: l10n.teacherAttemptsEmpty)
                          : Builder(
                              builder: (context) {
                                final groups = _groupAttempts(_attempts!);
                                final visibleGroups = _filterUserId == null
                                    ? groups
                                    : groups
                                        .where((g) => g.userId == _filterUserId)
                                        .toList();

                                if (visibleGroups.isEmpty) {
                                  return AppEmptyView(
                                    message: l10n.teacherAttemptsFilterEmpty,
                                  );
                                }

                                return AppPaddedScrollBody(
                                  includeTop: false,
                                  child: RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView(
                                    children: [
                                      _buildFilterBar(context, l10n, groups),
                                      for (var i = 0;
                                          i < visibleGroups.length;
                                          i++) ...[
                                        if (i > 0)
                                          const SizedBox(
                                            height: AppSpacing.sm,
                                          ),
                                        _buildStudentAccordion(
                                          context,
                                          l10n,
                                          visibleGroups[i],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
