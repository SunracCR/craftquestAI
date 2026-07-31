import 'dart:io';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_padded_scroll.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/widgets/practice_review_justification_panel.dart';
import 'package:craftquest_app/features/offline_practice/data/models/offline_models.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class OfflinePracticeReviewPage extends StatefulWidget {
  const OfflinePracticeReviewPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.questions,
  });

  final String quizId;
  final String quizTitle;
  final List<OfflineReviewQuestionModel> questions;

  @override
  State<OfflinePracticeReviewPage> createState() =>
      _OfflinePracticeReviewPageState();
}

class _OfflinePracticeReviewPageState extends State<OfflinePracticeReviewPage> {
  bool _showIncorrectOnly = false;

  bool _isIncorrectQuestion(OfflineReviewQuestionModel question) =>
      question.isCorrect != true;

  List<OfflineReviewQuestionModel> get _visibleQuestions {
    if (!_showIncorrectOnly) {
      return widget.questions;
    }
    return widget.questions.where(_isIncorrectQuestion).toList();
  }

  int get _incorrectCount =>
      widget.questions.where(_isIncorrectQuestion).length;

  bool _showStudentCorrectSelection(OfflineReviewAnswerOptionModel answer) =>
      answer.wasSelected && answer.isCorrect;

  bool _showStudentWrongSelection(OfflineReviewAnswerOptionModel answer) =>
      answer.wasSelected && !answer.isCorrect;

  bool _showRevealedCorrectAnswer(
    OfflineReviewQuestionModel question,
    OfflineReviewAnswerOptionModel answer,
  ) {
    if (!answer.isCorrect || answer.wasSelected) {
      return false;
    }
    return question.isCorrect != true;
  }

  Color _answerBorderColor(
    OfflineReviewQuestionModel question,
    OfflineReviewAnswerOptionModel answer,
  ) {
    if (_showStudentWrongSelection(answer)) {
      return AppColors.error;
    }
    if (_showStudentCorrectSelection(answer)) {
      return AppColors.accentMint;
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return AppColors.accentMint.withValues(alpha: 0.45);
    }
    return AppColors.textSecondary.withValues(alpha: 0.3);
  }

  Color? _answerFillColor(
    OfflineReviewQuestionModel question,
    OfflineReviewAnswerOptionModel answer,
  ) {
    if (_showStudentWrongSelection(answer)) {
      return AppColors.error.withValues(alpha: 0.12);
    }
    if (_showStudentCorrectSelection(answer)) {
      return AppColors.accentMint.withValues(alpha: 0.12);
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return AppColors.accentMint.withValues(alpha: 0.05);
    }
    return null;
  }

  Widget? _answerTrailingIcon(
    OfflineReviewQuestionModel question,
    OfflineReviewAnswerOptionModel answer,
  ) {
    if (_showStudentWrongSelection(answer)) {
      return const Icon(
        Icons.cancel_outlined,
        size: 20,
        color: AppColors.error,
      );
    }
    if (_showStudentCorrectSelection(answer)) {
      return const Icon(
        Icons.check_circle_outline,
        size: 20,
        color: AppColors.accentMint,
      );
    }
    if (_showRevealedCorrectAnswer(question, answer)) {
      return Icon(
        Icons.check_circle_outline,
        size: 20,
        color: AppColors.accentMint.withValues(alpha: 0.75),
      );
    }
    return null;
  }

  String? _answerTagLabel(
    AppLocalizations l10n,
    OfflineReviewQuestionModel question,
    OfflineReviewAnswerOptionModel answer,
  ) {
    if (_showRevealedCorrectAnswer(question, answer)) {
      return l10n.teacherReviewCorrectAnswerTag;
    }
    return null;
  }

  Widget? _buildJustification(
    AppLocalizations l10n,
    OfflineReviewQuestionModel question,
  ) {
    final text = question.justificationText?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return PracticeReviewJustificationPanel(
      title: l10n.practiceReviewJustificationTitle,
      expandHint: l10n.practiceReviewJustificationTapToExpand,
      text: text,
      sources: question.justificationSources
          .map(
            (s) => PracticeReviewJustificationSource(
              title: s.title,
              sourceUrl: s.sourceUrl,
              snippet: s.snippet,
              pageNumber: s.pageNumber,
              isPrimary: s.isPrimary,
            ),
          )
          .toList(),
      pageLabel: l10n.practiceReviewSourcePage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleQuestions = _visibleQuestions;

    return EdgeAwareScaffold(
      appBar: AppBar(
        title: Text(l10n.offlineLocalReviewTitle),
      ),
      body: AppPaddedScrollBody(
        child: ListView(
          children: [
            Text(
              widget.quizTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.offlineLocalReviewProvisionalNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.sessionReviewFilterAll),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.sessionReviewFilterIncorrect),
                ),
              ],
              selected: {_showIncorrectOnly},
              onSelectionChanged: (selection) {
                setState(() => _showIncorrectOnly = selection.first);
              },
            ),
            if (_showIncorrectOnly) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.sessionReviewIncorrectCount(_incorrectCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (visibleQuestions.isEmpty)
              Text(
                l10n.sessionReviewNoIncorrectQuestions,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              ...visibleQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionTitle(
                          title: l10n.teacherReviewQuestionLabel(
                            question.sortOrder,
                            question.questionText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (question.questionMediaAssetId != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _OfflineReviewMediaImage(
                            quizId: widget.quizId,
                            mediaAssetId: question.questionMediaAssetId!,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        ...question.answerOptions.map((answer) {
                          final tag = _answerTagLabel(l10n, question, answer);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusSm,
                                ),
                                border: Border.all(
                                  color: _answerBorderColor(question, answer),
                                ),
                                color: _answerFillColor(question, answer),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (answer.displayLabel.isNotEmpty)
                                    Text(
                                      '${answer.displayLabel}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                  if (answer.displayLabel.isNotEmpty)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (tag != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              tag,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        if ((answer.answerText ?? '')
                                            .isNotEmpty)
                                          Text(answer.answerText!),
                                        if (answer.mediaAssetId != null)
                                          _OfflineReviewMediaImage(
                                            quizId: widget.quizId,
                                            mediaAssetId: answer.mediaAssetId!,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_answerTrailingIcon(question, answer)
                                      case final icon?)
                                    icon,
                                ],
                              ),
                            ),
                          );
                        }),
                        if (_buildJustification(l10n, question)
                            case final justificationPanel?) ...[
                          const SizedBox(height: AppSpacing.sm),
                          justificationPanel,
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _OfflineReviewMediaImage extends StatelessWidget {
  const _OfflineReviewMediaImage({
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
