import 'package:craftquest_app/core/utils/assignment_dates.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_highlight_stat_row.dart';
import 'package:craftquest_app/core/widgets/app_notice_banner.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_score_summary_card.dart';
import 'package:craftquest_app/features/teacher/presentation/teacher_session_review_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PracticeResultPage extends StatelessWidget {
  const PracticeResultPage({
    super.key,
    required this.result,
    required this.quizTitle,
    this.elapsed,
  });

  final PracticeSessionResultModel result;
  final String quizTitle;
  final Duration? elapsed;

  String _reviewHiddenMessage(AppLocalizations l10n, String locale) {
    final mode = result.assignmentShowCorrectAnswersMode;
    if (mode == 'after_due_date') {
      final dueAt = result.assignmentDueAt;
      if (dueAt != null) {
        final dueLabel = AssignmentDates.formatWithLocale(
          locale,
          AssignmentDates.calendarUtc(dueAt),
        );
        return l10n.practiceReviewHiddenUntilDue(dueLabel);
      }
      return l10n.practiceReviewHiddenUntilDueNoDate;
    }
    return l10n.practiceReviewHiddenTeacherOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final canViewReview = result.canViewDetailedReview;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.practiceResultTitle),
      bottomBar: AppBottomActionBar(
        children: [
          if (canViewReview)
            AppGradientPrimaryButton(
              label: l10n.practiceViewResultsAction,
              icon: Icons.fact_check_outlined,
              onPressed: () => _viewResults(context),
            ),
          if (canViewReview) const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.practiceBackHomeAction,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppPageHeader(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                quizTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                if (!canViewReview) ...[
                  AppNoticeBanner(
                    message: _reviewHiddenMessage(l10n, locale),
                    variant: AppNoticeVariant.info,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                PracticeScoreSummaryCard(
                  percentage: result.percentage,
                  scoreObtained: result.scoreObtained,
                  scorePossible: result.scorePossible,
                  elapsed: elapsed,
                ),
                if (result.scoreTrendVsPrevious != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppNoticeBanner(
                    message: result.scoreTrendVsPrevious! >= 0
                        ? l10n.practiceResultTrendUp(
                            result.scoreTrendVsPrevious!.abs().toStringAsFixed(0),
                          )
                        : l10n.practiceResultTrendDown(
                            result.scoreTrendVsPrevious!.abs().toStringAsFixed(0),
                          ),
                    variant: result.scoreTrendVsPrevious! >= 0
                        ? AppNoticeVariant.success
                        : AppNoticeVariant.info,
                  ),
                ],
                if (canViewReview && result.questionsToReview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.practiceResultRepracticeTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...result.questionsToReview.map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppSectionCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.questionText,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _viewResults(context),
                              child: Text(l10n.practiceResultReviewQuestionAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppHighlightStatRow(
                  icon: Icons.check_circle_rounded,
                  label: l10n.practiceCorrectLabel(result.correctAnswers),
                  value: '${result.correctAnswers}',
                  color: AppColors.accentMint,
                ),
                AppHighlightStatRow(
                  icon: Icons.cancel_rounded,
                  label: l10n.practiceIncorrectLabel(result.incorrectAnswers),
                  value: '${result.incorrectAnswers}',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewResults(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionReviewPage(
          sessionId: result.practiceSessionId,
          quizTitle: quizTitle,
          isMyReview: true,
        ),
      ),
    );
  }
}
