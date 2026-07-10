import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/quiz_generation_parameters_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_review_text_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_upload_page.dart';
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
  });

  final String studyMaterialId;
  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  State<StudyMaterialOutlinePage> createState() => _StudyMaterialOutlinePageState();
}

class _StudyMaterialOutlinePageState extends State<StudyMaterialOutlinePage> {
  final _repository = getIt<StudyMaterialRepository>();
  bool _loading = true;
  String? _error;
  String? _errorDetail;
  bool _pageLimitFailure = false;
  bool _notSelectableFailure = false;

  @override
  void initState() {
    super.initState();
    _poll();
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
        setState(() {
          _error = DioErrorMapper.map(e);
          _loading = false;
        });
        return;
      } catch (_) {
        if (!mounted) return;
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) const AppLoadingView(),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.aiGenerationProcessing),
          ],
        ),
      ),
    );
  }
}
