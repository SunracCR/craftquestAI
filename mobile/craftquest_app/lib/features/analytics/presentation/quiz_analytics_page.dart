import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/analytics/data/analytics_repository.dart';
import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class QuizAnalyticsPage extends StatefulWidget {
  const QuizAnalyticsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.personalMode = false,
  });

  final String quizId;
  final String quizTitle;
  final bool personalMode;

  @override
  State<QuizAnalyticsPage> createState() => _QuizAnalyticsPageState();
}

class _QuizAnalyticsPageState extends State<QuizAnalyticsPage> {
  final _repository = getIt<AnalyticsRepository>();
  final _practiceRepository = getIt<PracticeRepository>();
  QuizAnalyticsModel? _analytics;
  MyQuizPracticeAnalyticsModel? _personalAnalytics;
  bool _loading = true;
  String? _error;
  bool _onlyDifficult = false;

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
      if (widget.personalMode) {
        final personal =
            await _practiceRepository.getMyQuizAnalytics(widget.quizId);
        if (!mounted) return;
        setState(() {
          _personalAnalytics = personal;
          _analytics = QuizAnalyticsModel(
            quizId: personal.quizId,
            totalPracticeSessions: personal.finishedAttempts,
            questions: personal.questions,
          );
          _loading = false;
        });
      } else {
        final analytics = await _repository.getQuizAnalytics(widget.quizId);
        if (!mounted) return;
        setState(() {
          _analytics = analytics;
          _personalAnalytics = null;
          _loading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final personal = _personalAnalytics;
    final questions = (_analytics?.questions ?? []).where((q) {
      if (!_onlyDifficult) return true;
      if (q.attemptsCount == 0) return false;
      final accuracy = q.correctCount / q.attemptsCount;
      return accuracy < 0.8;
    }).toList();

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: widget.personalMode
            ? l10n.myQuizAnalyticsTitle
            : l10n.quizAnalyticsTitle,
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _analytics == null
                  ? const SizedBox.shrink()
                  : AppPaddedScrollBody(
                      child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
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
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      AppStatusChip(
                                        label: widget.personalMode
                                            ? l10n.myQuizAnalyticsAttemptsLabel(
                                                _analytics!
                                                    .totalPracticeSessions,
                                              )
                                            : l10n.quizAnalyticsSessionsLabel(
                                                _analytics!
                                                    .totalPracticeSessions,
                                              ),
                                        color: AppColors.accentCool,
                                      ),
                                      if (personal?.averagePercentage != null)
                                        AppStatusChip(
                                          label: l10n.myQuizAnalyticsAverageLabel(
                                            personal!.averagePercentage!,
                                          ),
                                          color: AppColors.accentGold,
                                        ),
                                      if (personal?.bestPercentage != null)
                                        AppStatusChip(
                                          label: l10n.myQuizAnalyticsBestLabel(
                                            personal!.bestPercentage!,
                                          ),
                                          color: AppColors.accentMint,
                                        ),
                                      if (widget.personalMode)
                                        AppStatusChip(
                                          label: l10n.analyticsPersonalOnlyLabel,
                                          color: AppColors.accentViolet,
                                        ),
                                    ],
                                  ),
                                  if (widget.personalMode) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    FilterChip(
                                      label: Text(l10n.analyticsOnlyDifficultFilter),
                                      selected: _onlyDifficult,
                                      onSelected: (v) =>
                                          setState(() => _onlyDifficult = v),
                                      selectedColor: AppColors.teacherAccentSurface,
                                      checkmarkColor: AppColors.teacherAccent,
                                      labelStyle: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                ...questions.map((q) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AppSectionCard(
                                      padding: EdgeInsets.zero,
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 4,
                                              decoration: BoxDecoration(
                                                color: AppColors.accentCool,
                                                borderRadius:
                                                    const BorderRadius
                                                        .horizontal(
                                                  left: Radius.circular(
                                                    AppColors.radiusSm,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      q.questionText,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    AppMetaText(
                                                      text: l10n
                                                          .quizAnalyticsQuestionStats(
                                                        q.attemptsCount,
                                                        q.correctCount,
                                                        q.incorrectCount,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    if (widget.personalMode)
                                                      _PersonalAccuracyBar(
                                                        l10n: l10n,
                                                        question: q,
                                                      )
                                                    else
                                                      ...q.answerOptions.map(
                                                        (o) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              bottom: 8,
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  l10n.quizAnalyticsOptionLabel(
                                                                    o.stableKey,
                                                                    o.text ?? '',
                                                                    o.selectedCount,
                                                                    o.selectionRate,
                                                                    o.isCorrect
                                                                        ? ' ✓'
                                                                        : '',
                                                                  ),
                                                                  style: Theme.of(
                                                                    context,
                                                                  )
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                        color: o
                                                                                .isCorrect
                                                                            ? AppColors
                                                                                .accent
                                                                            : null,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                  child:
                                                                      LinearProgressIndicator(
                                                                    value: q.attemptsCount ==
                                                                            0
                                                                        ? 0
                                                                        : o.selectionRate /
                                                                            100,
                                                                    minHeight: 6,
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .background,
                                                                    color: o
                                                                            .isCorrect
                                                                        ? AppColors
                                                                            .accentMint
                                                                        : AppColors
                                                                            .accentSky,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                        ],
                      ),
                    ),
                    ),
    );
  }
}

class _PersonalAccuracyBar extends StatelessWidget {
  const _PersonalAccuracyBar({
    required this.l10n,
    required this.question,
  });

  final AppLocalizations l10n;
  final QuestionAnalyticsModel question;

  @override
  Widget build(BuildContext context) {
    final pct = question.attemptsCount == 0
        ? 0.0
        : question.correctCount / question.attemptsCount * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.analyticsPersonalAccuracyLabel(pct.toStringAsFixed(0)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.background,
            color: pct >= 70 ? AppColors.accentMint : AppColors.accentGold,
          ),
        ),
      ],
    );
  }
}
