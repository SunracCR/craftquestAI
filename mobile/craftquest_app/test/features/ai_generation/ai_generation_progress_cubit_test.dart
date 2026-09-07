import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai_generation/domain/ai_generation_job_gateway.dart';
import 'package:craftquest_app/features/ai_generation/presentation/cubit/ai_generation_progress_cubit.dart';
import 'package:craftquest_app/features/ai_generation/presentation/cubit/ai_generation_progress_state.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('AiGenerationProgressCubit', () {
    test('transient network errors keep polling until job completes', () async {
      final repository = _FakeAiRepository()
        ..responses = [
          _processingJob(),
          _processingJob(),
        ];
      repository.enqueueTransientFailure();
      repository.enqueueTransientFailure();
      repository.responses.add(_completedJob(importId: 'import-1', quizId: 'quiz-1'));

      final cubit = AiGenerationProgressCubit(
        aiRepository: repository,
        aiJobId: 'job-1',
        quizTitle: 'Quiz IA',
        targetQuizId: 'quiz-1',
      );

      await cubit.startPolling(l10n);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(cubit.state.status, AiGenerationProgressStatus.completed);
      expect(cubit.state.completionTarget?.importId, 'import-1');
      expect(repository.retryCalls, 0);

      await cubit.close();
    });

    test('refresh after resume reconciles completed job', () async {
      final repository = _FakeAiRepository()
        ..responses = [_completedJob(importId: 'import-2', quizId: 'quiz-2')];

      final cubit = AiGenerationProgressCubit(
        aiRepository: repository,
        aiJobId: 'job-2',
        quizTitle: 'Quiz IA',
        targetQuizId: 'quiz-2',
      );

      await cubit.refresh(l10n);

      expect(cubit.state.status, AiGenerationProgressStatus.completed);
      expect(cubit.state.completionTarget?.quizId, 'quiz-2');

      await cubit.close();
    });

    test('completed without import batch still completes with quiz target', () async {
      final repository = _FakeAiRepository()
        ..responses = [_completedJob(quizId: 'quiz-3')];

      final cubit = AiGenerationProgressCubit(
        aiRepository: repository,
        aiJobId: 'job-3',
        quizTitle: 'Quiz IA',
        targetQuizId: 'quiz-3',
      );

      await cubit.startPolling(l10n);

      expect(cubit.state.status, AiGenerationProgressStatus.completed);
      expect(cubit.state.completionTarget?.importId, isNull);
      expect(cubit.state.completionTarget?.quizId, 'quiz-3');

      await cubit.close();
    });

    test('retry on already completed job does not call retry endpoint', () async {
      final repository = _FakeAiRepository()
        ..responses = [_completedJob(importId: 'import-4', quizId: 'quiz-4')];

      final cubit = AiGenerationProgressCubit(
        aiRepository: repository,
        aiJobId: 'job-4',
        quizTitle: 'Quiz IA',
        targetQuizId: 'quiz-4',
      );

      await cubit.retry(l10n);

      expect(cubit.state.status, AiGenerationProgressStatus.completed);
      expect(repository.retryCalls, 0);

      await cubit.close();
    });

    test('server failed job is shown after verification', () async {
      final failed = _failedJob();
      final repository = _FakeAiRepository()
        ..responses = [failed, failed];

      final cubit = AiGenerationProgressCubit(
        aiRepository: repository,
        aiJobId: 'job-5',
        quizTitle: 'Quiz IA',
      );

      await cubit.startPolling(l10n);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(cubit.state.status, AiGenerationProgressStatus.failed);
      expect(cubit.state.failureMessage, isNotEmpty);

      await cubit.close();
    });
  });
}

AiJobModel _processingJob() {
  return AiJobModel(
    aiJobId: 'job-1',
    status: 'processing',
    jobType: 'generate_quiz',
    stage: 'generating',
    progressPercent: 40,
    createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
    startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
  );
}

AiJobModel _completedJob({String? importId, String? quizId}) {
  return AiJobModel(
    aiJobId: 'job-1',
    status: 'completed',
    jobType: 'generate_quiz',
    stage: 'completed',
    progressPercent: 100,
    questionImportBatchId: importId,
    targetQuizId: quizId,
    createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
    completedAt: DateTime.now().toUtc(),
  );
}

AiJobModel _failedJob() {
  return AiJobModel(
    aiJobId: 'job-5',
    status: 'failed',
    jobType: 'generate_quiz',
    stage: 'failed',
    errorCode: 'GENERATION_TIMEOUT',
    errorMessage: 'Generation exceeded the maximum time.',
    createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
    completedAt: DateTime.now().toUtc(),
  );
}

class _FakeAiRepository implements AiGenerationJobGateway {
  List<AiJobModel> responses = [];
  final List<Object> _queue = [];
  int retryCalls = 0;
  int _responseIndex = 0;

  void enqueueTransientFailure() {
    _queue.add(
      DioException(
        requestOptions: RequestOptions(path: '/api/ai/jobs/job-1'),
        type: DioExceptionType.connectionError,
      ),
    );
  }

  @override
  Future<AiJobModel> getJob(String aiJobId) async {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (next is Exception) {
        throw next;
      }
      if (next is DioException) {
        throw next;
      }
    }

    if (_responseIndex >= responses.length) {
      return responses.last;
    }

    return responses[_responseIndex++];
  }

  @override
  Future<void> retryGenerationJob(String aiJobId) async {
    retryCalls++;
  }
}
