import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_list_entry_card.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/presentation/practice_navigation.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/data/quiz_repository.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_content_setup_flow.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  late final QuizRepository _repository = getIt<QuizRepository>();
  late final PracticeRepository _practiceRepository = getIt<PracticeRepository>();
  List<QuizModel>? _quizzes;
  Map<String, PracticeActiveSessionModel> _inProgressByQuizId = {};
  String? _error;
  bool _loading = true;

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
      final quizzes = await _repository.getMyQuizzes();
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
      unawaited(_loadInProgressSessions());
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

  Future<void> _loadInProgressSessions() async {
    try {
      final inProgress = await _practiceRepository.getInProgressSessions();
      if (!mounted) return;
      setState(() {
        _inProgressByQuizId = {
          for (final s in inProgress) s.quizId: s,
        };
      });
    } catch (_) {
      // No bloquea la lista de cuestionarios si falla o tarda la práctica en curso.
    }
  }

  Future<void> _openCreate() async {
    QuizFlowAnchor.mark(context);
    final created = await QuizContentSetupFlow.createQuizWithSetup(context);
    if (created == null || !mounted) return;

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.quizzesTitle),
      bottomBar: _loading
          ? null
          : AppBottomActionBar(
              children: [
                AppGradientPrimaryButton(
                  label: l10n.createQuizAction,
                  icon: Icons.add_rounded,
                  onPressed: _openCreate,
                ),
              ],
            ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  title: l10n.quizzesLoadError,
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : (_quizzes == null || _quizzes!.isEmpty)
                  ? AppEmptyView(message: l10n.quizzesEmpty)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        itemCount: _quizzes!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final quiz = _quizzes![index];
                          final canPractice = quiz.publicationStatus ==
                                  'published' &&
                              quiz.questionCount > 0;
                          final activePractice =
                              _inProgressByQuizId[quiz.quizId];
                          final isPublished =
                              quiz.publicationStatus == 'published';
                          final accent = isPublished
                              ? AppColors.accentMint
                              : AppColors.accentGold;
                          var subtitle = l10n.quizListSubtitle(
                            quiz.publicationStatus,
                            quiz.questionCount,
                          );
                          if (quiz.hasPendingAiDraft) {
                            subtitle = '$subtitle\n${l10n.quizListPendingAiDraft}';
                          }
                          if (activePractice != null) {
                            subtitle =
                                '$subtitle\n${l10n.practiceInProgressSubtitle(activePractice.answeredCount, activePractice.totalQuestions)}';
                          }

                          return AppListEntryCard(
                            title: quiz.title,
                            subtitle: subtitle,
                            accentColor: accent,
                            leadingIcon: isPublished
                                ? Icons.check_circle_rounded
                                : Icons.edit_note_rounded,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => QuizDetailPage(
                                    quizId: quiz.quizId,
                                    quizTitle: quiz.title,
                                    publicationStatus:
                                        quiz.publicationStatus,
                                  ),
                                ),
                              );
                              await _load();
                            },
                            trailing: canPractice
                                ? IconButton(
                                    icon: Icon(
                                      activePractice != null
                                          ? Icons.play_circle_outline_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    color: AppColors.accent,
                                    tooltip: activePractice != null
                                        ? l10n.practiceContinueAction
                                        : l10n.practiceQuizAction,
                                    onPressed: () async {
                                      await openPracticeSession(
                                        context,
                                        quizId: quiz.quizId,
                                        quizTitle: quiz.title,
                                        resumeSessionId: activePractice
                                            ?.practiceSessionId,
                                      );
                                      if (!mounted) return;
                                      await _load();
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }
}
