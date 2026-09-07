import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/smoothed_progress_controller.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai_generation/presentation/cubit/ai_generation_progress_cubit.dart';
import 'package:craftquest_app/features/ai_generation/presentation/cubit/ai_generation_progress_state.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/ai_pipeline_progress_card.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiGenerationProgressPage extends StatelessWidget {
  const AiGenerationProgressPage({
    super.key,
    required this.aiJobId,
    required this.quizTitle,
    this.targetQuizId,
  });

  final String aiJobId;
  final String quizTitle;
  final String? targetQuizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiGenerationProgressCubit(
        aiRepository: getIt<AiRepository>(),
        aiJobId: aiJobId,
        quizTitle: quizTitle,
        targetQuizId: targetQuizId,
      ),
      child: _AiGenerationProgressView(
        quizTitle: quizTitle,
        targetQuizId: targetQuizId,
      ),
    );
  }
}

class _AiGenerationProgressView extends StatefulWidget {
  const _AiGenerationProgressView({
    required this.quizTitle,
    this.targetQuizId,
  });

  final String quizTitle;
  final String? targetQuizId;

  @override
  State<_AiGenerationProgressView> createState() =>
      _AiGenerationProgressViewState();
}

class _AiGenerationProgressViewState extends State<_AiGenerationProgressView>
    with WidgetsBindingObserver {
  final _smoothedProgress = SmoothedProgressController();
  final _importRepository = getIt<ImportRepository>();
  bool _handlingCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _smoothedProgress.addListener(_onSmoothedProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      unawaited(context.read<AiGenerationProgressCubit>().startPolling(l10n));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smoothedProgress.removeListener(_onSmoothedProgress);
    _smoothedProgress.disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final l10n = AppLocalizations.of(context)!;
      unawaited(context.read<AiGenerationProgressCubit>().refresh(l10n));
    }
  }

  void _onSmoothedProgress() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncProgressFromJob(AiJobModel? job) {
    if (job == null) {
      return;
    }
    _smoothedProgress.updateFromServer(
      progressPercent: job.progressPercent,
      stage: job.stage,
      isActiveGeneration: job.isActiveGeneration,
    );
  }

  Future<void> _handleCompletion(AiGenerationCompletionTarget target) async {
    if (_handlingCompletion || !mounted) {
      return;
    }
    _handlingCompletion = true;

    try {
      unawaited(getIt<NotificationsCubit>().refreshUnreadCount());

      if (target.opensPreview) {
        final importId = target.importId!;
        await _importRepository.prefetchPreview(importId);
        if (!mounted) {
          return;
        }

        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ImportPreviewPage(
              importId: importId,
              quizTitle: target.quizTitle,
              initialStatus: ImportStatusModel(
                importId: importId,
                status: 'ready_for_review',
                totalQuestionsDetected: 0,
                validQuestions: 0,
                questionsWithWarnings: 0,
                questionsWithErrors: 0,
              ),
              fromAiGeneration: true,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        final quizId = target.quizId ?? widget.targetQuizId;
        if (confirmed == true && quizId != null) {
          if (QuizFlowAnchor.hasAnchor) {
            QuizFlowAnchor.returnToAnchor(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => QuizDetailPage(
                  quizId: quizId,
                  quizTitle: target.quizTitle,
                ),
              ),
              (route) => route.isFirst,
            );
          }
        } else if (QuizFlowAnchor.hasAnchor) {
          QuizFlowAnchor.returnToAnchor(context);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      final quizId = target.quizId ?? widget.targetQuizId;
      if (quizId != null) {
        if (QuizFlowAnchor.hasAnchor) {
          QuizFlowAnchor.returnToAnchor(context);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => QuizDetailPage(
                quizId: quizId,
                quizTitle: target.quizTitle,
              ),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      _handlingCompletion = false;
      if (mounted) {
        context.read<AiGenerationProgressCubit>().acknowledgeCompletion();
      }
    }
  }

  void _goHome() {
    final l10n = AppLocalizations.of(context)!;
    context.showInfoSnackBar(l10n.aiGenerationBackgroundSnack);
    unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _progressSubtitle(AppLocalizations l10n, AiGenerationProgressState state) {
    final job = state.job;
    if (job == null) {
      return l10n.aiGenerationProgressSubtitle;
    }

    if (state.showLongRunningHint) {
      return l10n.aiGenerationProgressTakingLong;
    }

    if (job.isDeferredRetry) {
      if (job.nextRetryAt != null) {
        final minutes =
            job.nextRetryAt!.difference(DateTime.now().toUtc()).inMinutes;
        if (minutes > 0) {
          return l10n.aiGenerationProgressDeferredRetryMinutes(
            minutes.clamp(1, 999),
          );
        }
      }
      return l10n.aiGenerationProgressDeferredRetry;
    }

    if (job.retryAttempt > 0) {
      return l10n.aiGenerationProgressAutoRetry(job.retryAttempt);
    }

    if (job.isActiveGeneration && job.stage != null) {
      return job.stageLabel(l10n);
    }

    return l10n.aiGenerationProgressSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AiGenerationProgressCubit, AiGenerationProgressState>(
      listenWhen: (previous, current) =>
          previous.job != current.job ||
          previous.completionTarget != current.completionTarget,
      listener: (context, state) {
        _syncProgressFromJob(state.job);
        final target = state.completionTarget;
        if (target != null) {
          unawaited(_handleCompletion(target));
        }
      },
      builder: (context, state) {
        final canLeave = state.isFailed && !state.isRetrying;
        final job = state.job;
        final displayPercent = _smoothedProgress.displayPercent;
        final showDeterminate = job?.isActiveGeneration == true &&
            (job?.progressPercent != null || displayPercent > 0);

        return PopScope(
          canPop: canLeave,
          child: EdgeAwareScaffold(
            appBar: craftQuestAppBar(
              title: l10n.aiGenerationProgressTitle,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: _goHome,
                  tooltip: l10n.practiceBackHomeAction,
                  icon: const Icon(Icons.home_rounded),
                ),
              ],
            ),
            body: state.isFailed
                ? AppErrorView(
                    message: state.failureMessage ?? l10n.aiGenerationFailed,
                    detail: state.failureDetail,
                    retryLabel: l10n.aiGenerationRetryAction,
                    onRetry: () {
                      _smoothedProgress.reset();
                      unawaited(
                        context.read<AiGenerationProgressCubit>().retry(l10n),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      AiPipelineProgressCard(
                        title: widget.quizTitle,
                        subtitle: _progressSubtitle(l10n, state),
                        percent: displayPercent,
                        l10n: l10n,
                        showStepper: job?.isActiveGeneration == true,
                        stage: job?.stage,
                        status: job?.status ?? 'processing',
                        showStalledPulse: _smoothedProgress.isStalled,
                        indeterminate: !showDeterminate,
                        footer: Column(
                          children: [
                            Text(
                              l10n.aiGenerationBackgroundSnack,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            if (job?.isDeferredRetry == true) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.aiGenerationCreditsNotConsumed,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            AppSecondaryButton(
                              label: l10n.practiceBackHomeAction,
                              icon: Icons.home_rounded,
                              accentColor: AppColors.accentCool,
                              onPressed: _goHome,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
