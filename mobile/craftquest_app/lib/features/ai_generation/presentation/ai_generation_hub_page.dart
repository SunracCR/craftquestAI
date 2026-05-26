import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_activity_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_materials_library_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_upload_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiGenerationHubPage extends StatelessWidget {
  const AiGenerationHubPage({super.key, this.targetQuizId, this.targetQuizTitle});

  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationHubTitle),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: AppColors.accentMint.withValues(alpha: 0.9),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.aiGenerationHubSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppGradientPrimaryButton(
                label: l10n.aiGenerationHubAction,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StudyMaterialUploadPage(
                        targetQuizId: targetQuizId,
                        targetQuizTitle: targetQuizTitle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: l10n.aiActivityAction,
                icon: Icons.inbox_rounded,
                accentColor: AppColors.accentCool,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AiActivityPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: l10n.aiGenerationLibraryAction,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AiGenerationMaterialsLibraryPage(
                        targetQuizId: targetQuizId,
                        targetQuizTitle: targetQuizTitle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
