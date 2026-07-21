import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/smoothed_progress_controller.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/quiz_generation_parameters_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_review_text_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_upload_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/ai_pipeline_progress_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Pantalla de espera mientras el material se procesa; redirige a
/// [QuizGenerationParametersPage] cuando está listo.
class StudyMaterialOutlinePage extends StatefulWidget {
  const StudyMaterialOutlinePage({
    super.key,
    required this.studyMaterialId,
    this.targetQuizId,
    this.targetQuizTitle,
    this.fileName,
  });

  final String studyMaterialId;
  final String? targetQuizId;
  final String? targetQuizTitle;
  final String? fileName;

  @override
  State<StudyMaterialOutlinePage> createState() => _StudyMaterialOutlinePageState();
}

class _StudyMaterialOutlinePageState extends State<StudyMaterialOutlinePage> {
  final _repository = getIt<StudyMaterialRepository>();
  final _analysisProgress = EstimatedAnalysisProgressController();
  bool _loading = true;
  String? _error;
  String? _errorDetail;
  bool _pageLimitFailure = false;
  bool _notSelectableFailure = false;

  @override
  void initState() {
    super.initState();
    _analysisProgress.addListener(_onProgressTick);
    _analysisProgress.start();
    _poll();
  }

  @override
  void dispose() {
    _analysisProgress.removeListener(_onProgressTick);
    _analysisProgress.disposeController();
    super.dispose();
  }

  void _onProgressTick() {
    if (mounted) setState(() {});
  }

  Future<void> _poll() async {
    while (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _errorDetail = null;
        _pageLimitFailure = false;
        _notSelectableFailure = false;
      });
      try {
        final detail = await _repository.getDetail(widget.studyMaterialId);
        if (!mounted) return;

        if (detail.processingStatus == 'failed') {
          _analysisProgress.stop();
          final l10n = AppLocalizations.of(context)!;
          final pageLimit = ApiErrorMapper.isMaterialPageLimitFailure(
            detail.errorMessage,
          );
          final notSelectable = ApiErrorMapper.isMaterialNotSelectableTextFailure(
            detail.errorMessage,
          );
          setState(() {
            _loading = false;
            _pageLimitFailure = pageLimit;
            _notSelectableFailure = notSelectable;
            _error = ApiErrorMapper.mapMaterialProcessingFailure(
              detail.errorMessage,
              l10n,
            );
            _errorDetail = ApiErrorMapper.mapMaterialFailureGuidance(
                  detail.errorMessage,
                  l10n,
                ) ??
                (pageLimit
                    ? l10n.errorMaterialPageLimitGuidance(
                        AiGenerationLimits.maxPagesPerMaterial,
                      )
                    : null);
          });
          return;
        }

        if (detail.isReady) {
          _analysisProgress.stop();
          if (detail.requiresTextReview) {
            if (!mounted) return;
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => StudyMaterialReviewTextPage(
                  studyMaterialId: widget.studyMaterialId,
                  initialDetail: detail,
                  targetQuizId: widget.targetQuizId,
                  targetQuizTitle: widget.targetQuizTitle,
                ),
              ),
            );
            return;
          }

          if (!mounted) return;
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => QuizGenerationParametersPage(
                studyMaterialId: widget.studyMaterialId,
                detail: detail,
                targetQuizId: widget.targetQuizId,
                targetQuizTitle: widget.targetQuizTitle,
              ),
            ),
          );
          return;
        }

        setState(() => _loading = false);
        await Future<void>.delayed(const Duration(seconds: 2));
      } on DioException catch (e) {
        if (!mounted) return;
        _analysisProgress.stop();
        setState(() {
          _error = DioErrorMapper.map(e);
          _loading = false;
        });
        return;
      } catch (_) {
        if (!mounted) return;
        _analysisProgress.stop();
        setState(() {
          _error = DioErrorMapper.genericMessage();
          _loading = false;
        });
        return;
      }
    }
  }

  void _goToUploadAnotherFile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StudyMaterialUploadPage(
          targetQuizId: widget.targetQuizId,
          targetQuizTitle: widget.targetQuizTitle,
        ),
      ),
    );
  }

  Widget _analysisSteps(AppLocalizations l10n) {
    final percent = _analysisProgress.displayPercent;
    final step = percent < 30
        ? 0
        : percent < 55
            ? 1
            : 2;

    Widget row(int index, String label) {
      final done = index < step;
      final active = index == step;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : active
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
              size: 20,
              color: done
                  ? AppColors.accentMint
                  : active
                      ? AppColors.accentCool
                      : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(0, l10n.aiPipelineStepUploadDone),
        row(1, l10n.aiPipelineStepExtracting),
        row(2, l10n.aiPipelineStepPreparing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_error != null) {
      return EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.aiGenerationOutlineTitle),
        body: AppErrorView(
          message: _error!,
          detail: _errorDetail,
          retryLabel: _pageLimitFailure || _notSelectableFailure || _errorDetail != null
              ? l10n.aiGenerationUploadAnotherFileAction
              : l10n.retry,
          onRetry: _pageLimitFailure || _notSelectableFailure || _errorDetail != null
              ? _goToUploadAnotherFile
              : _poll,
        ),
      );
    }

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationOutlineTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AiPipelineProgressCard(
            title: l10n.aiPipelineAnalyzingTitle,
            subtitle: widget.fileName ?? l10n.aiPipelineAnalyzingSubtitle,
            percent: _analysisProgress.displayPercent,
            l10n: l10n,
            showStalledPulse: _analysisProgress.displayPercent >= 55,
            footer: _analysisSteps(l10n),
          ),
          if (_loading) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: AppLoadingView()),
          ],
        ],
      ),
    );
  }
}
