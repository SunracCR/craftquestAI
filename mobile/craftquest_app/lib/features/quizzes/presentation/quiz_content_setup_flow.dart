import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_hub_page.dart';
import 'package:craftquest_app/features/imports/presentation/excel_import_page.dart';
import 'package:craftquest_app/features/imports/presentation/import_questions_page.dart';
import 'package:craftquest_app/features/quizzes/data/models/quiz_models.dart';
import 'package:craftquest_app/features/quizzes/presentation/add_question_page.dart';
import 'package:craftquest_app/features/quizzes/presentation/create_quiz_page.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_flow_anchor.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum _ContentSetupChoice { addManual, import, ai, skip }

/// Tras crear un cuestionario, guía al usuario a añadir preguntas manualmente o importarlas.
abstract final class QuizContentSetupFlow {
  static Future<QuizModel?> createQuizWithSetup(BuildContext context) async {
    final created = await Navigator.of(context).push<QuizModel>(
      MaterialPageRoute(builder: (_) => const CreateQuizPage()),
    );
    if (created == null || !context.mounted) return null;
    await promptContentSetup(context, quiz: created);
    return created;
  }

  static Future<void> promptContentSetup(
    BuildContext context, {
    required QuizModel quiz,
  }) async {
    final choice = await showModalBottomSheet<_ContentSetupChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContentSetupSheet(quizTitle: quiz.title),
    );

    if (!context.mounted || choice == null || choice == _ContentSetupChoice.skip) {
      return;
    }

    switch (choice) {
      case _ContentSetupChoice.addManual:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AddQuestionPage(quizId: quiz.quizId),
          ),
        );
      case _ContentSetupChoice.import:
        await openImportFlow(
          context,
          quizId: quiz.quizId,
          quizTitle: quiz.title,
        );
      case _ContentSetupChoice.ai:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AiGenerationHubPage(
              targetQuizId: quiz.quizId,
              targetQuizTitle: quiz.title,
            ),
          ),
        );
      case _ContentSetupChoice.skip:
        break;
    }

    if (context.mounted) {
      QuizFlowAnchor.returnToAnchor(context);
    }
  }

  static Future<void> openImportFlow(
    BuildContext context, {
    required String quizId,
    required String quizTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.importExcelAction),
              onTap: () => Navigator.pop(ctx, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.importQuestionsTitle),
              subtitle: Text(
                '${l10n.importFormatJson} / ${l10n.importFormatTxt}',
              ),
              onTap: () => Navigator.pop(ctx, 'text'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;

    final page = choice == 'excel'
        ? ExcelImportPage(quizId: quizId, quizTitle: quizTitle)
        : ImportQuestionsPage(quizId: quizId, quizTitle: quizTitle);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _ContentSetupSheet extends StatelessWidget {
  const _ContentSetupSheet({required this.quizTitle});

  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.createQuizNextStepTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.createQuizNextStepSubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (quizTitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                quizTitle,
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _SetupOptionTile(
              icon: Icons.edit_note_rounded,
              title: l10n.createQuizAddQuestionsManually,
              onTap: () =>
                  Navigator.pop(context, _ContentSetupChoice.addManual),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SetupOptionTile(
              icon: Icons.upload_file_rounded,
              title: l10n.createQuizImportQuestions,
              subtitle: '${l10n.importFormatJson} / ${l10n.importFormatTxt}',
              onTap: () => Navigator.pop(context, _ContentSetupChoice.import),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SetupOptionTile(
              icon: Icons.auto_awesome_rounded,
              title: l10n.aiGenerationFromQuizAction,
              subtitle: l10n.aiGenerationHubSubtitle,
              onTap: () => Navigator.pop(context, _ContentSetupChoice.ai),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, _ContentSetupChoice.skip),
              child: Text(l10n.createQuizSkipQuestionsSetup),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SetupOptionTile extends StatelessWidget {
  const _SetupOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
