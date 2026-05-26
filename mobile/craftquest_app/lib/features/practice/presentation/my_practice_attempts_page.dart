import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_attempt_format.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class MyPracticeAttemptsPage extends StatefulWidget {
  const MyPracticeAttemptsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<MyPracticeAttemptsPage> createState() => _MyPracticeAttemptsPageState();
}

class _MyPracticeAttemptsPageState extends State<MyPracticeAttemptsPage> {
  final _repository = getIt<PracticeRepository>();
  List<MyPracticeAttemptModel>? _attempts;
  bool _loading = true;
  String? _error;

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
      final attempts = await _repository.listMyQuizAttempts(widget.quizId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _loading = false;
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

  Color _scoreColor(double obtained, double possible) {
    if (possible <= 0) return AppColors.textSecondary;
    final ratio = obtained / possible;
    if (ratio >= 0.7) return AppColors.accentMint;
    if (ratio >= 0.4) return AppColors.accentGold;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attempts = _attempts;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.myPracticeAttemptsTitle),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : attempts == null || attempts.isEmpty
                  ? AppEmptyView(message: l10n.myPracticeAttemptsEmpty)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: AppSpacing.listBottom,
                        itemCount: attempts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final attempt = attempts[index];
                          final pct = attempt.scorePossible > 0
                              ? (attempt.scoreObtained /
                                      attempt.scorePossible *
                                      100)
                                  .toStringAsFixed(0)
                              : '0';
                          return AppListEntryCard(
                            title: l10n.teacherAttemptRowTitle(
                              formatTeacherAttemptDate(
                                context,
                                attempt.sortDate,
                              ),
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
                            accentColor: _scoreColor(
                              attempt.scoreObtained,
                              attempt.scorePossible,
                            ),
                            leadingIcon: Icons.assignment_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TeacherSessionReviewPage(
                                    sessionId: attempt.practiceSessionId,
                                    quizTitle: widget.quizTitle,
                                    isMyReview: true,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
