import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/question_type_labels.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Vista de autor para una pregunta en detalle de cuestionario.
class AppQuestionCard extends StatelessWidget {
  const AppQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.l10n,
  });

  final int index;
  final QuestionModel question;
  final AppLocalizations l10n;

  List<AnswerOptionModel> get _visibleOptions => question.answerOptions
      .where((o) => !o.stableKey.isQuestionStemOption)
      .toList();

  Set<String> get _correctIds => question.correctAnswerOptionIds.toSet();

  String get _correctKeysLabel {
    final keys = _visibleOptions
        .where((o) => _correctIds.contains(o.answerOptionId))
        .map((o) => o.stableKey)
        .toList();
    if (keys.isEmpty) return '';
    final joined = keys.join(', ');
    return keys.length == 1
        ? l10n.quizDetailCorrectKeys(joined)
        : l10n.quizDetailCorrectKeysPlural(joined);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.questionTypeAccent(question.questionType);
    final textTheme = Theme.of(context).textTheme;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor,
                    typeColor.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IndexBadge(index: index, color: typeColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppStatusChip(
                          label: question.questionType.displayLabel(l10n),
                          color: typeColor,
                        ),
                      ),
                      Text(
                        l10n.quizDetailOptionCount(_visibleOptions.length),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        question.text,
                        style: textTheme.titleMedium?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.correctAnswerKeyLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ..._visibleOptions.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _OptionPreviewTile(
                        option: option,
                        isCorrect: _correctIds.contains(option.answerOptionId),
                        accentColor: typeColor,
                      ),
                    ),
                  ),
                  if (_correctKeysLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentMint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppColors.accentMint,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _correctKeysLabel,
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentMint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionPreviewTile extends StatelessWidget {
  const _OptionPreviewTile({
    required this.option,
    required this.isCorrect,
    required this.accentColor,
  });

  final AnswerOptionModel option;
  final bool isCorrect;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final text = option.text?.trim();
    final displayText =
        (text == null || text.isEmpty) ? '—' : text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.accentMint.withValues(alpha: 0.1)
            : AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? AppColors.accentMint.withValues(alpha: 0.55)
              : AppColors.textSecondary.withValues(alpha: 0.18),
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KeyBadge(
              label: option.stableKey,
              color: isCorrect ? AppColors.accentMint : accentColor,
              filled: isCorrect,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.3,
                      color: isCorrect
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.92),
                    ),
              ),
            ),
            if (isCorrect)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppColors.accentMint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Q$index',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.28) : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filled ? AppColors.textPrimary : color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
