import 'dart:io';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_local_grader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_sync_manager.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OfflinePracticeSessionPage extends StatelessWidget {
  const OfflinePracticeSessionPage({
    super.key,
    required this.quizTitle,
  });

  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(quizTitle),
      ),
      body: BlocBuilder<OfflinePracticeSessionCubit, OfflinePracticeSessionState>(
        builder: (context, state) {
          switch (state.status) {
            case OfflinePracticeSessionStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case OfflinePracticeSessionStatus.error:
              return AppErrorView(
                message: state.errorMessage ?? 'Error al cargar sesión offline.',
                retryLabel: 'Reintentar',
                onRetry: () => context.read<OfflinePracticeSessionCubit>().load(),
              );
            case OfflinePracticeSessionStatus.finished:
              return _FinishedView(state: state);
            case OfflinePracticeSessionStatus.ready:
            case OfflinePracticeSessionStatus.answering:
              return _QuestionView(state: state);
          }
        },
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state});

  final OfflinePracticeSessionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OfflinePracticeSessionCubit>();
    final question = state.currentQuestion;
    if (question == null) {
      return const AppEmptyView(
        icon: Icons.quiz_outlined,
        message: 'Sin preguntas',
      );
    }

    final feedback = state.feedbackByQuestion[question.questionId];
    final selected = state.selections[question.questionId] ?? {};
    final displayOptions = question.answerOptions
        .where((o) => !OfflineLocalGrader.isQuestionImageStem(o.stableKey))
        .toList()
      ..sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pregunta ${state.currentIndex + 1} de ${state.totalQuestions}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (question.questionMediaAssetId != null) ...[
            const SizedBox(height: AppSpacing.md),
            _OfflineMediaImage(
              quizId: state.quiz!.quizId,
              mediaAssetId: question.questionMediaAssetId!,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: displayOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final option = displayOptions[index];
                final isSelected = selected.contains(option.answerOptionId);
                return Material(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: feedback == null
                        ? () => cubit.toggleSelection(
                              questionId: question.questionId,
                              answerOptionId: option.answerOptionId,
                              supportsMultiple:
                                  question.supportsMultipleCorrectAnswers,
                            )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (option.answerText != null &&
                                    option.answerText!.isNotEmpty)
                                  Text(option.answerText!),
                                if (option.mediaAssetId != null)
                                  _OfflineMediaImage(
                                    quizId: state.quiz!.quizId,
                                    mediaAssetId: option.mediaAssetId!,
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.accent),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (feedback != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              feedback.isCorrect ? 'Correcta (provisional)' : 'Incorrecta (provisional)',
              style: TextStyle(
                color: feedback.isCorrect ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Anterior',
                  onPressed: state.currentIndex > 0
                      ? () => cubit.goToQuestion(state.currentIndex - 1)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppPrimaryButton(
                  label: feedback == null ? 'Confirmar' : 'Siguiente',
                  onPressed: () async {
                    if (feedback == null) {
                      await cubit.submitCurrentQuestion();
                      return;
                    }
                    if (state.currentIndex + 1 >= state.totalQuestions) {
                      await cubit.finishSession();
                    } else {
                      cubit.goToQuestion(state.currentIndex + 1);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.state});

  final OfflinePracticeSessionState state;

  @override
  Widget build(BuildContext context) {
    final result = state.finishResult!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resultado provisional',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Puntuación: ${result.scoreObtained}/${result.scorePossible}'),
          Text('Porcentaje: ${result.percentage}%'),
          Text('Correctas: ${result.correctAnswers}'),
          Text('Incorrectas: ${result.incorrectAnswers}'),
          Text('Omitidas: ${result.omittedAnswers}'),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'El resultado oficial se confirmará al sincronizar con el servidor.',
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Sincronizar ahora',
            onPressed: () async {
              await getIt<OfflineSyncManager>().syncPendingSessions();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OfflineMediaImage extends StatelessWidget {
  const _OfflineMediaImage({
    required this.quizId,
    required this.mediaAssetId,
  });

  final String quizId;
  final String mediaAssetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getIt<OfflinePackageRepository>().resolveLocalMediaPath(
        quizId: quizId,
        mediaAssetId: mediaAssetId,
      ),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: Icon(Icons.image_not_supported_outlined)),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            height: 180,
          ),
        );
      },
    );
  }
}
