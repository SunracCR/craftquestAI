import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/imports/data/import_error_messages.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/imports/data/models/import_models.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ImportPreviewPage extends StatefulWidget {
  const ImportPreviewPage({
    super.key,
    required this.importId,
    required this.quizTitle,
    required this.initialStatus,
    this.fromAiGeneration = false,
  });

  final String importId;
  final String quizTitle;
  final ImportStatusModel initialStatus;
  final bool fromAiGeneration;

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  final _repository = getIt<ImportRepository>();
  final _aiRepository = getIt<AiRepository>();
  ImportPreviewModel? _preview;
  ImportStatusModel? _status;
  bool _loading = true;
  bool _confirming = false;
  bool _aiNormalizing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _load();
  }

  Future<void> _normalizeWithAi() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _aiNormalizing = true);
    try {
      await _aiRepository.normalizeImportBatch(widget.importId);
      if (!mounted) return;
      context.showSuccessSnackBar(l10n.aiNormalizeSuccess);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _aiNormalizing = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _repository.getPreview(widget.importId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
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
        _error = DioErrorMapper.genericMessage();
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _confirming = true);
    try {
      final result = await _repository.confirm(widget.importId);
      if (!mounted) return;
      if (result.skippedDueToPlanLimit > 0 &&
          result.maxQuestionsPerQuiz != null) {
        context.showInfoSnackBar(
          l10n.importPlanLimitConfirmNotice(
            result.createdQuestions,
            result.planName ?? 'Free',
            result.maxQuestionsPerQuiz!,
            result.skippedDueToPlanLimit,
          ),
        );
      } else {
        context.showSuccessSnackBar(
          l10n.importConfirmSuccess(result.createdQuestions),
        );
      }
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _status ?? widget.initialStatus;
    final importableCount =
        _preview?.importableQuestionCount ?? _preview?.questions.length;
    final canConfirm = _loading
        ? status.validQuestions > 0
        : (importableCount ?? status.validQuestions) > 0;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.importPreviewTitle),
      bottomBar: AppBottomActionBar(
        children: [
          if (!widget.fromAiGeneration && status.questionsWithErrors > 0)
            AppSecondaryButton(
              label: l10n.aiImproveImportAction,
              isLoading: _aiNormalizing,
              onPressed: _normalizeWithAi,
            ),
          AppGradientPrimaryButton(
            label: l10n.importConfirmAction,
            isLoading: _confirming,
            onPressed: canConfirm ? _confirm : null,
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.quizTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          AppMetaText(
                            text: l10n.importSummaryLabel(
                              status.validQuestions,
                              status.totalQuestionsDetected,
                              status.questionsWithErrors,
                            ),
                          ),
                          if (_preview != null &&
                              !canConfirm &&
                              _preview!.questions.isNotEmpty &&
                              _preview!.maxQuestionsPerQuiz != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.block_rounded,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.importConfirmDisabledQuizFull(
                                          _preview!.maxQuestionsPerQuiz!,
                                          _preview!.currentQuestionCountInQuiz,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_preview != null && _preview!.hasPlanImportCap) ...[
                            const SizedBox(height: AppSpacing.sm),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppColors.accentGold.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: AppColors.accentGold,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.importPlanLimitPreviewNotice(
                                          _preview!.planName ?? 'Free',
                                          _preview!.maxQuestionsPerQuiz!,
                                          _preview!.currentQuestionCountInQuiz,
                                          _preview!.importableQuestionCount,
                                          _preview!.questions.length,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(height: 1.4),
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
                    if (_preview != null && _preview!.errors.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _preview!.errors.length,
                          itemBuilder: (context, index) {
                            final err = _preview!.errors[index];
                            return Text(
                              l10n.importErrorLine(
                                err.rowNumber ?? 0,
                                ImportErrorMessages.localize(err, l10n),
                              ),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: err.severity == 'error'
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: _preview?.questions.length ?? 0,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final q = _preview!.questions[index];
                          final pointsLabel = q.points == q.points.roundToDouble()
                              ? q.points.toInt().toString()
                              : q.points.toString();
                          return AppSectionCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${q.text}',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                AppMetaText(
                                  text:
                                      '${l10n.importQuestionTypeLabel(q.type)} · ${l10n.questionPointsValue(pointsLabel)}',
                                ),
                                if (widget.fromAiGeneration) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  AppStatusChip(
                                    label: l10n.importAiGeneratedBadge,
                                    color: AppColors.accentMint,
                                  ),
                                ],
                                if (ImportErrorMessages.isImageType(q.type)) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  AppStatusChip(
                                    label: l10n.importImagePendingBadge,
                                    color: AppColors.accentCool,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                ...q.answerOptions.map(
                                  (o) => Text(
                                    l10n.importAnswerLine(
                                      o.key,
                                      o.text ?? '',
                                      q.correctAnswerKeys.contains(o.key)
                                          ? ' ✓'
                                          : '',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: q.correctAnswerKeys
                                                  .contains(o.key)
                                              ? AppColors.accentMint
                                              : null,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
