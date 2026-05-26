import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/features/ai_generation/data/models/study_material_models.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/ai_generation_progress_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_outline_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_review_text_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/utils/ai_job_stage_labels.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/study_material_library_card.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AiGenerationMaterialsLibraryPage extends StatefulWidget {
  const AiGenerationMaterialsLibraryPage({
    super.key,
    this.targetQuizId,
    this.targetQuizTitle,
  });

  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  State<AiGenerationMaterialsLibraryPage> createState() =>
      _AiGenerationMaterialsLibraryPageState();
}

class _AiGenerationMaterialsLibraryPageState
    extends State<AiGenerationMaterialsLibraryPage> {
  final _repository = getIt<StudyMaterialRepository>();
  List<StudyMaterialSummaryModel>? _items;
  bool _loading = true;
  String? _error;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(e);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.aiGenerationFailed;
        _loading = false;
      });
    }
  }

  Future<void> _openMaterial(StudyMaterialSummaryModel item) async {
    if (item.hasPendingReviewDraft) {
      final importId = item.pendingReviewImportId!;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImportPreviewPage(
            importId: importId,
            quizTitle: item.title,
            initialStatus: ImportStatusModel(
              importId: importId,
              status: 'ready_for_review',
              totalQuestionsDetected: 0,
              validQuestions: 0,
              questionsWithWarnings: 0,
              questionsWithErrors: 0,
            ),
            fromAiGeneration: true,
          ),
        ),
      );
      if (mounted) {
        await _load();
      }
      return;
    }

    if (item.hasActiveGenerationJob && item.activeAiJobId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AiGenerationProgressPage(
            aiJobId: item.activeAiJobId!,
            targetQuizId: widget.targetQuizId,
            quizTitle: widget.targetQuizTitle ?? item.title,
          ),
        ),
      );
      if (mounted) {
        await _load();
      }
      return;
    }

    try {
      final detail = await _repository.getDetail(item.studyMaterialId);
      if (!mounted) return;

      if (detail.requiresTextReview) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudyMaterialReviewTextPage(
              studyMaterialId: item.studyMaterialId,
              initialDetail: detail,
              targetQuizId: widget.targetQuizId,
              targetQuizTitle: widget.targetQuizTitle,
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudyMaterialOutlinePage(
            studyMaterialId: item.studyMaterialId,
            targetQuizId: widget.targetQuizId,
            targetQuizTitle: widget.targetQuizTitle,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _confirmDelete(StudyMaterialSummaryModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        title: Text(l10n.deleteStudyMaterialConfirmTitle),
        content: Text(l10n.deleteStudyMaterialConfirmMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteStudyMaterialAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = item.studyMaterialId);
    try {
      await _repository.delete(item.studyMaterialId);
      if (!mounted) return;
      setState(() {
        _items = _items?.where((m) => m.studyMaterialId != item.studyMaterialId).toList();
        _deletingId = null;
      });
      context.showSuccessSnackBar(l10n.studyMaterialDeletedMessage);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      context.showErrorSnackBar(l10n.aiGenerationFailed);
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentCool.withValues(alpha: 0.25),
                    AppColors.accentGold.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accentCool.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.accentCool,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.aiGenerationLibraryEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiGenerationLibraryEmptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StudyMaterialLibraryRetentionBanner(
              hint: l10n.aiGenerationLibraryRetentionHint(
                AiGenerationLimits.retentionDays,
              ),
              materialCountLabel: l10n.aiGenerationLibraryMaterialCount(0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.aiGenerationLibraryTitle),
        body: const Center(child: AppLoadingView()),
      );
    }

    if (_error != null) {
      return EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.aiGenerationLibraryTitle),
        body: AppErrorView(
          message: _error!,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
      );
    }

    final items = _items ?? [];
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationLibraryTitle),
      body: items.isEmpty
          ? _buildEmptyState(l10n)
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                itemCount: items.length + 1,
                separatorBuilder: (_, index) =>
                    SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StudyMaterialLibraryRetentionBanner(
                      hint: l10n.aiGenerationLibraryRetentionHint(
                        AiGenerationLimits.retentionDays,
                      ),
                      materialCountLabel: l10n.aiGenerationLibraryMaterialCount(
                        items.length,
                      ),
                    );
                  }

                  final item = items[index - 1];
                  final isDeleting = _deletingId == item.studyMaterialId;

                  final generationChip = _generationChip(l10n, item);

                  return StudyMaterialLibraryCard(
                    title: item.title,
                    fileType: item.fileType,
                    statusLabel: StudyMaterialLibraryLabels.statusLabel(
                      l10n,
                      item.processingStatus,
                    ),
                    statusColor: StudyMaterialLibraryLabels.statusColor(
                      item.processingStatus,
                    ),
                    uploadedLabel: StudyMaterialLibraryLabels.uploadedLabel(
                      l10n,
                      item.createdAt,
                      dateFormat,
                    ),
                    expiryLabel: StudyMaterialLibraryLabels.expiryLabel(
                      l10n,
                      item.retentionExpiresAt,
                      dateFormat,
                    ),
                    generationChipLabel: generationChip?.label,
                    generationChipColor: generationChip?.color,
                    showReviewBadge: item.needsOcr && generationChip == null,
                    reviewLabel: l10n.aiGenerationLibraryNeedsReview,
                    isDeleting: isDeleting,
                    deleteTooltip: l10n.deleteStudyMaterialAction,
                    onTap: () => _openMaterial(item),
                    onDelete: () => _confirmDelete(item),
                  );
                },
              ),
            ),
    );
  }

  ({String label, Color color})? _generationChip(
    AppLocalizations l10n,
    StudyMaterialSummaryModel item,
  ) {
    if (item.hasPendingReviewDraft) {
      return (
        label: l10n.aiLibraryStatusDraftReady,
        color: AppColors.accentMint,
      );
    }
    if (item.hasActiveGenerationJob) {
      return (
        label: AiJobStageLabels.stageLabel(
          l10n,
          item.activeAiJobStage,
          item.activeAiJobStatus ?? 'processing',
        ),
        color: AppColors.accentCool,
      );
    }
    return null;
  }
}
