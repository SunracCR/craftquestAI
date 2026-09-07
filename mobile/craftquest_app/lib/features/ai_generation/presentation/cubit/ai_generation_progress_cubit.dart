import 'dart:async';

import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai_generation/domain/ai_generation_job_gateway.dart';
import 'package:craftquest_app/features/ai_generation/presentation/cubit/ai_generation_progress_state.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aligns with backend [GenerationJobTimeoutMaxMinutes] (25) plus margin.
const aiGenerationPollMaxDuration = Duration(minutes: 28);

const _longRunningHintThreshold = Duration(minutes: 8);

const _pollIntervalPending = Duration(seconds: 2);
const _pollIntervalProcessing = Duration(milliseconds: 500);

const _transientBackoffSteps = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
];

class AiGenerationProgressCubit extends Cubit<AiGenerationProgressState> {
  AiGenerationProgressCubit({
    required AiGenerationJobGateway aiRepository,
    required String aiJobId,
    required String quizTitle,
    this.targetQuizId,
  })  : _aiRepository = aiRepository,
        _aiJobId = aiJobId,
        _quizTitle = quizTitle,
        super(const AiGenerationProgressState());

  final AiGenerationJobGateway _aiRepository;
  final String _aiJobId;
  final String _quizTitle;
  final String? targetQuizId;

  int _pollGeneration = 0;
  DateTime? _processingSince;

  Future<void> startPolling(AppLocalizations l10n) async {
    final generation = ++_pollGeneration;
    emit(
      state.copyWith(
        status: AiGenerationProgressStatus.polling,
        clearFailure: true,
        clearCompletion: true,
      ),
    );
    await _pollLoop(l10n, generation);
  }

  /// Reconcile job state after app resume or push notification.
  Future<void> refresh(AppLocalizations l10n) async {
    if (state.status == AiGenerationProgressStatus.completed) {
      return;
    }

    try {
      final job = await _fetchJobWithRaceCheck(l10n);
      if (isClosed) {
        return;
      }

      if (_tryEmitCompletion(job)) {
        return;
      }

      if (job.isFailed) {
        emit(_failedState(job, l10n));
        return;
      }

      if (job.isActiveGeneration) {
        emit(
          state.copyWith(
            status: AiGenerationProgressStatus.polling,
            job: job,
            showLongRunningHint: _shouldShowLongRunningHint(job),
            clearFailure: true,
          ),
        );
        final generation = ++_pollGeneration;
        unawaited(_pollLoop(l10n, generation));
      }
    } on DioException catch (e) {
      if (isClosed) {
        return;
      }
      if (_isTerminalAuthError(e)) {
        emit(_dioFailedState(e, l10n));
      }
    } catch (_) {
      // Best-effort refresh; keep current UI if reconciliation fails.
    }
  }

  Future<void> retry(AppLocalizations l10n) async {
    if (state.isRetrying) {
      return;
    }

    emit(
      state.copyWith(
        status: AiGenerationProgressStatus.retrying,
        clearFailure: true,
        clearJob: true,
        showLongRunningHint: false,
      ),
    );
    _processingSince = null;

    try {
      final job = await _aiRepository.getJob(_aiJobId);
      if (isClosed) {
        return;
      }

      if (_tryEmitCompletion(job)) {
        return;
      }

      if (!job.isFailed) {
        emit(
          state.copyWith(
            status: AiGenerationProgressStatus.polling,
            job: job,
            clearFailure: true,
          ),
        );
        final generation = ++_pollGeneration;
        unawaited(_pollLoop(l10n, generation));
        return;
      }

      await _aiRepository.retryGenerationJob(_aiJobId);
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: AiGenerationProgressStatus.polling,
          clearFailure: true,
        ),
      );
      final generation = ++_pollGeneration;
      unawaited(_pollLoop(l10n, generation));
    } on DioException catch (e) {
      if (isClosed) {
        return;
      }
      emit(_dioFailedState(e, l10n));
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: AiGenerationProgressStatus.failed,
          failureMessage: DioErrorMapper.genericMessage(l10n),
        ),
      );
    }
  }

  void acknowledgeCompletion() {
    emit(state.copyWith(clearCompletion: true));
  }

  @override
  Future<void> close() {
    _pollGeneration++;
    return super.close();
  }

  Future<void> _pollLoop(AppLocalizations l10n, int generation) async {
    final deadline = DateTime.now().add(aiGenerationPollMaxDuration);
    var transientStep = 0;

    while (!isClosed && generation == _pollGeneration && DateTime.now().isBefore(deadline)) {
      try {
        final job = await _aiRepository.getJob(_aiJobId);
        if (isClosed || generation != _pollGeneration) {
          return;
        }

        transientStep = 0;
        _trackProcessingSince(job);

        emit(
          state.copyWith(
            status: AiGenerationProgressStatus.polling,
            job: job,
            showLongRunningHint: _shouldShowLongRunningHint(job),
            clearFailure: true,
          ),
        );

        if (job.isFailed) {
          final verified = await _verifyFailedJob(l10n);
          if (isClosed || generation != _pollGeneration) {
            return;
          }
          if (verified != null && _tryEmitCompletion(verified)) {
            return;
          }
          emit(_failedState(verified ?? job, l10n));
          return;
        }

        if (_tryEmitCompletion(job)) {
          return;
        }

        await Future<void>.delayed(_pollIntervalFor(job));
      } on DioException catch (e) {
        if (isClosed || generation != _pollGeneration) {
          return;
        }

        if (_isTerminalAuthError(e)) {
          emit(_dioFailedState(e, l10n));
          return;
        }

        if (DioErrorMapper.isTransientFailure(e)) {
          final delay = _transientBackoffSteps[
              transientStep.clamp(0, _transientBackoffSteps.length - 1)];
          transientStep = (transientStep + 1).clamp(0, _transientBackoffSteps.length - 1);
          await Future<void>.delayed(delay);
          continue;
        }

        emit(_dioFailedState(e, l10n));
        return;
      } catch (_) {
        if (isClosed || generation != _pollGeneration) {
          return;
        }

        final delay = _transientBackoffSteps[
            transientStep.clamp(0, _transientBackoffSteps.length - 1)];
        transientStep = (transientStep + 1).clamp(0, _transientBackoffSteps.length - 1);
        await Future<void>.delayed(delay);
      }
    }

    if (isClosed || generation != _pollGeneration) {
      return;
    }

    await _handlePollDeadline(l10n, generation);
  }

  Future<void> _handlePollDeadline(AppLocalizations l10n, int generation) async {
    try {
      final job = await _aiRepository.getJob(_aiJobId);
      if (isClosed || generation != _pollGeneration) {
        return;
      }

      if (_tryEmitCompletion(job)) {
        return;
      }

      if (job.isFailed) {
        emit(_failedState(job, l10n));
        return;
      }

      if (job.isActiveGeneration) {
        emit(
          state.copyWith(
            status: AiGenerationProgressStatus.polling,
            job: job,
            showLongRunningHint: true,
            clearFailure: true,
          ),
        );
        final nextGeneration = ++_pollGeneration;
        unawaited(_pollLoop(l10n, nextGeneration));
        return;
      }
    } catch (_) {
      // Fall through to generic failure below.
    }

    if (isClosed || generation != _pollGeneration) {
      return;
    }

    emit(
      state.copyWith(
        status: AiGenerationProgressStatus.failed,
        failureMessage: l10n.aiGenerationFailed,
      ),
    );
  }

  Future<AiJobModel> _fetchJobWithRaceCheck(AppLocalizations l10n) async {
    var job = await _aiRepository.getJob(_aiJobId);
    if (job.isFailed) {
      final verified = await _verifyFailedJob(l10n);
      if (verified != null) {
        job = verified;
      }
    }
    return job;
  }

  Future<AiJobModel?> _verifyFailedJob(AppLocalizations l10n) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      final job = await _aiRepository.getJob(_aiJobId);
      if (job.isCompleted || job.isActiveGeneration) {
        return job;
      }
      return job.isFailed ? job : null;
    } catch (_) {
      return null;
    }
  }

  bool _tryEmitCompletion(AiJobModel job) {
    if (!job.isCompleted) {
      return false;
    }

    final importId = job.questionImportBatchId;
    final quizId = job.targetQuizId ?? targetQuizId;
    if (importId == null && quizId == null) {
      return false;
    }

    emit(
      state.copyWith(
        status: AiGenerationProgressStatus.completed,
        job: job,
        completionTarget: AiGenerationCompletionTarget(
          importId: importId,
          quizId: quizId,
          quizTitle: _quizTitle,
        ),
        clearFailure: true,
      ),
    );
    return true;
  }

  AiGenerationProgressState _failedState(AiJobModel job, AppLocalizations l10n) {
    return state.copyWith(
      status: AiGenerationProgressStatus.failed,
      job: job,
      failureMessage: ApiErrorMapper.mapAiJobFailure(job, l10n),
      failureDetail: job.creditsWereNotConsumed
          ? l10n.aiGenerationCreditsNotConsumed
          : null,
    );
  }

  AiGenerationProgressState _dioFailedState(DioException e, AppLocalizations l10n) {
    final status = e.response?.statusCode;
    return state.copyWith(
      status: AiGenerationProgressStatus.failed,
      failureMessage: status == 401
          ? l10n.errorSessionExpired
          : DioErrorMapper.map(e, l10n),
    );
  }

  bool _isTerminalAuthError(DioException e) => e.response?.statusCode == 401;

  void _trackProcessingSince(AiJobModel job) {
    if (job.status == 'processing' && _processingSince == null) {
      _processingSince = DateTime.now();
    }
  }

  bool _shouldShowLongRunningHint(AiJobModel job) {
    if (!job.isActiveGeneration) {
      return false;
    }

    final serverAge = job.age;
    if (serverAge != null && serverAge > _longRunningHintThreshold) {
      return true;
    }

    return _processingSince != null &&
        DateTime.now().difference(_processingSince!) > _longRunningHintThreshold;
  }

  Duration _pollIntervalFor(AiJobModel job) {
    if (job.status == 'pending' || job.isDeferredRetry) {
      return _pollIntervalPending;
    }
    return _pollIntervalProcessing;
  }
}
