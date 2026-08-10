import 'dart:io';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/question_type_labels.dart';
import 'package:craftquest_app/core/widgets/app_answer_tile.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/widgets/practice_selection_hint.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_local_grader.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_sync_manager.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_state.dart';
import 'package:craftquest_app/features/offline_practice/presentation/offline_practice_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
              final message = state.errorMessage == 'offline_download_needs_update'
                  ? l10n.offlineDownloadNeedsUpdate
                  : (state.errorMessage ?? l10n.genericRequestErrorMessage);
              return AppErrorView(
                message: message,
                retryLabel: l10n.retry,
                onRetry: () => context.read<OfflinePracticeSessionCubit>().load(),
              );
            case OfflinePracticeSessionStatus.finished:
              return _FinishedView(
                state: state,
                quizTitle: quizTitle,
              );
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
    final l10n = AppLocalizations.of(context)!;
    final question = state.currentQuestion;
    if (question == null) {
      return const AppEmptyView(
        icon: Icons.quiz_outlined,
        message: 'Sin preguntas',
      );
    }

    final selected = state.selections[question.questionId] ?? {};
    final displayOptions = question.answerOptions
        .where((o) => !OfflineLocalGrader.isQuestionImageStem(o.stableKey))
        .toList()
      ..sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));

    final isLastQuestion = state.currentIndex + 1 >= state.totalQuestions;
    final isSingleSelect = isSingleSelectQuestionType(question.questionType);
    final selectionMode = isSingleSelect
        ? AnswerSelectionMode.single
        : AnswerSelectionMode.multiple;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.practiceQuestionCounter(
              state.currentIndex + 1,
              state.totalQuestions,
            ),
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
          const SizedBox(height: AppSpacing.md),
          PracticeSelectionHint(
            isSingleSelect: isSingleSelect,
            questionType: question.questionType,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              itemCount: displayOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final option = displayOptions[index];
                final isSelected = selected.contains(option.answerOptionId);
                final answerText = option.answerText?.trim();
                final label = answerText != null && answerText.isNotEmpty
                    ? answerText
                    : option.stableKey;
                return AppAnswerTile(
                  label: label,
                  selected: isSelected,
                  selectionMode: selectionMode,
                  mediaChild: option.mediaAssetId != null
                      ? _OfflineMediaImage(
                          quizId: state.quiz!.quizId,
                          mediaAssetId: option.mediaAssetId!,
                        )
                      : null,
                  onTap: () => cubit.toggleSelection(
                    questionId: question.questionId,
                    answerOptionId: option.answerOptionId,
                    supportsMultiple: question.supportsMultipleCorrectAnswers,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.practicePreviousQuestionAction,
                  onPressed: state.currentIndex > 0
                      ? () => cubit.goToQuestion(state.currentIndex - 1)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppPrimaryButton(
                  label: isLastQuestion
                      ? l10n.offlineFinishAction
                      : l10n.offlineNextAction,
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          if (isLastQuestion) {
                            await cubit.finishSession();
                          } else {
                            await cubit.answerAndContinue();
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
  const _FinishedView({
    required this.state,
    required this.quizTitle,
  });

  final OfflinePracticeSessionState state;
  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = state.finishResult!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.offlineProvisionalResultTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.practiceScoreLabel(result.scoreObtained, result.scorePossible)),
          Text(l10n.practicePercentageLabel(result.percentage)),
          Text(l10n.practiceCorrectLabel(result.correctAnswers)),
          Text(l10n.practiceIncorrectLabel(result.incorrectAnswers)),
          Text(l10n.offlineResultOmittedLabel(result.omittedAnswers)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.offlineSyncPendingNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          AppPrimaryButton(
            label: l10n.offlineViewDetailedReview,
            icon: Icons.fact_check_outlined,
            onPressed: state.reviewQuestions.isEmpty
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => OfflinePracticeReviewPage(
                          quizId: state.quiz!.quizId,
                          quizTitle: quizTitle,
                          questions: state.reviewQuestions,
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: l10n.closeAction,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.offlineSyncNow,
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
