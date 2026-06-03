import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/analytics/data/models/analytics_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class QuestionDistractorCard extends StatelessWidget {
  const QuestionDistractorCard({
    super.key,
    required this.question,
    required this.l10n,
  });

  final QuestionAnalyticsModel question;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.quizAnalyticsQuestionStats(
            question.attemptsCount,
            question.correctCount,
            question.incorrectCount,
          ),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...question.answerOptions.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quizAnalyticsOptionLabel(
                    o.stableKey,
                    o.text ?? '',
                    o.selectedCount,
                    o.selectionRate,
                    o.isCorrect ? ' ✓' : '',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: o.isCorrect ? AppColors.accent : null,
                      ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: question.attemptsCount == 0
                        ? 0
                        : o.selectionRate / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    color: o.isCorrect
                        ? AppColors.accentMint
                        : AppColors.accentSky,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
