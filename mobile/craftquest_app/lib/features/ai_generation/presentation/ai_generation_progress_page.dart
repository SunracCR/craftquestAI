import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Aligns with backend [StaleProcessingMinutes] (appsettings AiGeneration).
const _staleJobThreshold = Duration(minutes: 12);
const _longRunningHint = Duration(minutes: 8);
const _pollIntervalPending = Duration(seconds: 2);
const _pollIntervalProcessing = Duration(milliseconds: 500);

class AiGenerationProgressPage extends StatefulWidget {
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
  State<AiGenerationProgressPage> createState() => _AiGenerationProgressPageState();
}

class _AiGenerationProgressPageState extends State<AiGenerationProgressPage> {
  final _aiRepository = getIt<AiRepository>();
  final _importRepository = getIt<ImportRepository>();
  String? _error;
  String? _errorDetail;
  AiJobModel? _job;
  bool _isRetrying = false;
  bool _stuckDetected = false;
  DateTime? _processingSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_poll());
    });
  }

  bool _isJobStale(AiJobModel job) {
    if (!job.isActiveGeneration) {
      return false;
    }

    final serverAge = job.age;
    if (serverAge != null && serverAge > _staleJobThreshold) {
      return true;
    }

    return _processingSince != null &&
        DateTime.now().difference(_processingSince!) > _staleJobThreshold;
  }

  void _showStuckError(AppLocalizations l10n) {
    setState(() {
      _stuckDetected = true;
      _error = l10n.aiGenerationProgressStuck;
      _errorDetail = l10n.aiGenerationProgressStuckDetail;
    });
  }

  Duration _pollIntervalFor(AiJobModel job) {
    if (job.status == 'pending' || job.isDeferredRetry) {
      return _pollIntervalPending;
    }
    return _pollIntervalProcessing;
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final deadline = DateTime.now().add(const Duration(minutes: 35));

    while (mounted && DateTime.now().isBefore(deadline)) {
      try {
        final job = await _aiRepository.getJob(widget.aiJobId);
        if (!mounted) return;

        setState(() {
          _job = job;
          _error = null;
          _errorDetail = null;
          _stuckDetected = false;
          if (job.status == 'processing' && _processingSince == null) {
            _processingSince = DateTime.now();
          }
        });

        if (job.isFailed) {
          unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
          setState(() {
            _error = ApiErrorMapper.mapAiJobFailure(job, l10n);
            _errorDetail = job.creditsWereNotConsumed
                ? l10n.aiGenerationCreditsNotConsumed
                : null;
          });
          return;
        }

        if (_isJobStale(job)) {
          _showStuckError(l10n);
          return;
        }

        if (job.isCompleted && job.questionImportBatchId != null) {
          unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
          final importId = job.questionImportBatchId!;
          await _importRepository.prefetchPreview(importId);
          if (!mounted) return;

          final quizId = job.targetQuizId ?? widget.targetQuizId;
          final confirmed = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => ImportPreviewPage(
                importId: importId,
                quizTitle: widget.quizTitle,
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

          if (!mounted) return;
          if (confirmed == true && quizId != null) {
            if (QuizFlowAnchor.hasAnchor) {
              QuizFlowAnchor.returnToAnchor(context);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => QuizDetailPage(
                    quizId: quizId,
                    quizTitle: widget.quizTitle,
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

        await Future<void>.delayed(_pollIntervalFor(job));
      } on DioException catch (e) {
        if (!mounted) return;
        final status = e.response?.statusCode;
        setState(() {
          _error = status == 401
              ? l10n.errorSessionExpired
              : DioErrorMapper.map(e);
        });
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _error = DioErrorMapper.genericMessage());
        return;
      }
    }

    if (mounted && _error == null) {
      setState(() => _error = l10n.aiGenerationFailed);
    }
  }

  Future<void> _retryFailedJob() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _error = null;
      _errorDetail = null;
      _job = null;
      _stuckDetected = false;
      _processingSince = null;
    });

    try {
      await _aiRepository.retryGenerationJob(widget.aiJobId);
      if (!mounted) return;
      setState(() => _isRetrying = false);
      unawaited(_poll());
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _error = DioErrorMapper.map(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _error = DioErrorMapper.genericMessage();
      });
    }
  }

  void _goBackToRetry() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _goHome() {
    final l10n = AppLocalizations.of(context)!;
    context.showInfoSnackBar(l10n.aiGenerationBackgroundSnack);
    unawaited(getIt<NotificationsCubit>().refreshUnreadCount());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _progressSubtitle(AppLocalizations l10n) {
    final job = _job;
    if (job == null) {
      return l10n.aiGenerationProgressSubtitle;
    }

    if (job.isDeferredRetry) {
      if (job.nextRetryAt != null) {
        final minutes = job.nextRetryAt!.difference(DateTime.now().toUtc()).inMinutes;
        if (minutes > 0) {
          return l10n.aiGenerationProgressDeferredRetryMinutes(minutes.clamp(1, 999));
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

    final elapsed = job.age ?? (_processingSince != null
        ? DateTime.now().difference(_processingSince!)
        : null);

    if (job.status == 'processing' &&
        elapsed != null &&
        elapsed > _longRunningHint) {
      return l10n.aiGenerationProgressTakingLong;
    }

    return l10n.aiGenerationProgressSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canLeave = _error != null && !_isRetrying;

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
      body: _error != null
          ? AppErrorView(
              message: _error!,
              detail: _errorDetail,
              retryLabel: _stuckDetected
                  ? l10n.aiGenerationStuckGoBackAction
                  : l10n.aiGenerationRetryAction,
              onRetry: _stuckDetected ? _goBackToRetry : _retryFailedJob,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_job?.progressPercent != null &&
                        _job!.isActiveGeneration) ...[
                      SizedBox(
                        width: 280,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _job!.progressPercent! / 100,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.aiGenerationProgressPercent(_job!.progressPercent!),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ] else
                      const AppLoadingView(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _progressSubtitle(l10n),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.aiGenerationBackgroundSnack,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_job?.isDeferredRetry == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.aiGenerationCreditsNotConsumed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppSecondaryButton(
                      label: l10n.practiceBackHomeAction,
                      icon: Icons.home_rounded,
                      accentColor: AppColors.accentCool,
                      onPressed: _goHome,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
