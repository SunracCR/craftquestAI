import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/data/models/study_material_models.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/quiz_generation_parameters_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class StudyMaterialReviewTextPage extends StatefulWidget {
  const StudyMaterialReviewTextPage({
    super.key,
    required this.studyMaterialId,
    required this.initialDetail,
    this.targetQuizId,
    this.targetQuizTitle,
  });

  final String studyMaterialId;
  final StudyMaterialDetailModel initialDetail;
  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  State<StudyMaterialReviewTextPage> createState() =>
      _StudyMaterialReviewTextPageState();
}

class _StudyMaterialReviewTextPageState extends State<StudyMaterialReviewTextPage> {
  final _repository = getIt<StudyMaterialRepository>();
  late final TextEditingController _textController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialDetail.buildDraftExtractedText(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _repository.updateExtractedText(
        studyMaterialId: widget.studyMaterialId,
        extractedText: text,
      );
      final detail = await _repository.getDetail(widget.studyMaterialId);
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
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationReviewTextTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.aiGenerationReviewTextSave,
            isLoading: _saving,
            onPressed: _saving || _textController.text.trim().isEmpty
                ? null
                : _saveAndContinue,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aiGenerationReviewTextHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
