import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai/data/ai_repository.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/imports/presentation/excel_import_page.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ImportQuestionsPage extends StatefulWidget {
  const ImportQuestionsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<ImportQuestionsPage> createState() => _ImportQuestionsPageState();
}

class _ImportQuestionsPageState extends State<ImportQuestionsPage> {
  final _repository = getIt<ImportRepository>();
  final _aiRepository = getIt<AiRepository>();
  final _contentController = TextEditingController();
  String _sourceType = 'json';
  bool _loading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _normalizeWithAi() async {
    final l10n = AppLocalizations.of(context)!;
    final rawText = _contentController.text.trim();
    if (rawText.isEmpty) {
      context.showErrorSnackBar(l10n.importContentRequired);
      return;
    }

    setState(() => _loading = true);
    try {
      final json = await _aiRepository.normalizeRawText(rawText: rawText);
      if (!mounted) return;
      setState(() {
        _contentController.text = json;
        _sourceType = 'json';
        _loading = false;
      });
      context.showSuccessSnackBar(l10n.aiNormalizeSuccess);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _process() async {
    final l10n = AppLocalizations.of(context)!;
    final rawText = _contentController.text.trim();
    if (rawText.isEmpty) {
      context.showErrorSnackBar(l10n.importContentRequired);
      return;
    }

    setState(() => _loading = true);
    try {
      final status = await _repository.processImport(
        quizId: widget.quizId,
        sourceType: _sourceType,
        rawText: rawText,
      );
      if (!mounted) return;
      if (status.validQuestions == 0) {
        context.showErrorSnackBar(l10n.importNoValidQuestions);
        setState(() => _loading = false);
        return;
      }

      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ImportPreviewPage(
            importId: status.importId,
            quizTitle: widget.quizTitle,
            initialStatus: status,
          ),
        ),
      );
      if (!mounted) return;
      if (confirmed == true) {
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _contentHint(AppLocalizations l10n) => _sourceType == 'txt'
      ? l10n.importContentHintTxt
      : l10n.importContentHintJson;

  String _formatHelp(AppLocalizations l10n) => _sourceType == 'txt'
      ? l10n.importFormatTxtHelp
      : l10n.importFormatJsonHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.importQuestionsTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppSecondaryButton(
            label: l10n.aiNormalizeAction,
            isLoading: _loading,
            onPressed: _normalizeWithAi,
          ),
          AppGradientPrimaryButton(
            label: l10n.importProcessAction,
            isLoading: _loading,
            onPressed: _process,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.quizTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: l10n.importExcelAction,
                  icon: Icons.table_chart_outlined,
                  onPressed: _loading
                      ? null
                      : () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) => ExcelImportPage(
                                quizId: widget.quizId,
                                quizTitle: widget.quizTitle,
                              ),
                            ),
                          );
                          if (ok == true && mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _sourceType,
                  decoration: InputDecoration(labelText: l10n.importFormatLabel),
                  items: [
                    DropdownMenuItem(
                      value: 'json',
                      child: Text(l10n.importFormatJson),
                    ),
                    DropdownMenuItem(
                      value: 'txt',
                      child: Text(l10n.importFormatTxt),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _sourceType = value);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatHelp(l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.importFormatUnsureHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: l10n.importContentLabel,
                  hintText: _contentHint(l10n),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
