import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/imports/data/import_repository.dart';
import 'package:craftquest_app/features/imports/presentation/import_preview_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelImportPage extends StatefulWidget {
  const ExcelImportPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends State<ExcelImportPage> {
  final _repository = getIt<ImportRepository>();

  bool _uploading = false;
  bool _downloadingTemplate = false;
  bool _dragOver = false;
  String? _selectedFileName;
  Uint8List? _selectedBytes;

  bool get _hasFile => _selectedBytes != null && _selectedFileName != null;

  bool get _supportsFileDrop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool get _canUpload => !_uploading && _hasFile;

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _downloadingTemplate = true);
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final bytes = await _repository.downloadExcelTemplate(
        languageCode: languageCode,
      );
      if (!mounted) return;

      final file = XFile.fromData(
        bytes,
        name: 'craftquest_import_template.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (kIsWeb) {
        await Share.shareXFiles([file], text: l10n.excelImportTemplateReady);
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/craftquest_import_template.xlsx';
        await file.saveTo(path);
        await Share.shareXFiles(
          [XFile(path)],
          text: l10n.excelImportTemplateReady,
        );
      }

      if (!mounted) return;
      context.showSuccessSnackBar(l10n.excelImportTemplateReady);
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.excelImportTemplateFailed);
    } finally {
      if (mounted) setState(() => _downloadingTemplate = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    _applyPickedFile(result.files.single);
  }

  void _clearFile() {
    setState(() {
      _selectedFileName = null;
      _selectedBytes = null;
    });
  }

  void _applyPickedFile(PlatformFile file) {
    final l10n = AppLocalizations.of(context)!;
    final name = file.name;
    if (!name.toLowerCase().endsWith('.xlsx')) {
      context.showErrorSnackBar(l10n.excelImportOnlyXlsx);
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      context.showErrorSnackBar(l10n.excelImportReadFailed);
      return;
    }

    if (bytes.length > ImportRepository.maxExcelFileBytes) {
      context.showErrorSnackBar(l10n.excelImportFileTooLarge);
      return;
    }

    setState(() {
      _selectedFileName = name;
      _selectedBytes = bytes;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _selectedBytes;
    final name = _selectedFileName;
    if (bytes == null || name == null) {
      context.showErrorSnackBar(l10n.excelImportSelectFileFirst);
      return;
    }

    setState(() => _uploading = true);
    try {
      final status = await _repository.processExcelFile(
        quizId: widget.quizId,
        bytes: bytes,
        fileName: name,
      );
      if (!mounted) return;

      if (status.validQuestions == 0) {
        context.showErrorSnackBar(l10n.importNoValidQuestions);
        setState(() => _uploading = false);
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildQuizHeader(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHighlight,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
              child: const Icon(
                Icons.grid_on_rounded,
                color: AppColors.accentGold,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.quizTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.excelImportSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnsCard(AppLocalizations l10n) {
    return AppSectionCard(
      variant: AppCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.view_column_rounded,
                size: 20,
                color: AppColors.accentCool.withValues(alpha: 0.95),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.excelImportColumnsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.excelImportColumnsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: const [
              _ColumnChip(label: 'Pregunta'),
              _ColumnChip(label: 'Tipo'),
              _ColumnChip(label: 'A–E'),
              _ColumnChip(label: 'Correcta'),
              _ColumnChip(label: 'Puntos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: l10n.excelImportTemplateSection),
        AppSectionCard(
          variant: AppCardVariant.warm,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceSecondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.onSurfaceSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.excelImportDownloadTemplate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: _downloadingTemplate ? null : _downloadTemplate,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.onSurfaceSecondary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.onSurfaceSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: _downloadingTemplate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _dropZoneDecoration() {
    if (_hasFile) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.importFileReadySurface,
            AppColors.importFileReadySurfaceEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.accentMint.withValues(alpha: 0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentMint.withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }

    if (_dragOver) {
      return BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(
          color: AppColors.accentGold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      border: Border.all(
        color: AppColors.textSecondary.withValues(alpha: 0.35),
        width: 1.5,
      ),
    );
  }

  Widget _buildDropZoneContent(AppLocalizations l10n) {
    if (_hasFile) {
      final fileName = _selectedFileName!;
      final sizeLabel = _formatFileSize(_selectedBytes!.length);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentMint.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.accentMint.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: AppColors.accentMint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppStatusChip(
            label: l10n.excelImportFileReady,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_rounded,
                  size: 20,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    fileName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sizeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accentMint.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: _uploading ? null : _clearFile,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: Text(l10n.excelImportChangeFile),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 52,
          color: _dragOver ? AppColors.accentGold : AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.excelImportDropHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.excelImportDropSubhint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSecondaryButton(
          label: l10n.excelImportPickFile,
          icon: Icons.folder_open_rounded,
          accentColor: AppColors.accentGold,
          onPressed: _uploading ? null : _pickFile,
        ),
      ],
    );
  }

  Widget _buildDropZone(AppLocalizations l10n) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: 300,
      width: double.infinity,
      decoration: _dropZoneDecoration(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _buildDropZoneContent(l10n),
    );

    if (!_supportsFileDrop) {
      return content;
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragOver = true),
      onDragExited: (_) => setState(() => _dragOver = false),
      onDragDone: (details) {
        setState(() => _dragOver = false);
        if (_uploading || details.files.isEmpty) {
          return;
        }
        final file = details.files.first;
        final name = file.name;
        if (!name.toLowerCase().endsWith('.xlsx')) {
          context.showErrorSnackBar(l10n.excelImportOnlyXlsx);
          return;
        }
        file.readAsBytes().then((bytes) {
          if (!mounted) return;
          if (bytes.length > ImportRepository.maxExcelFileBytes) {
            context.showErrorSnackBar(l10n.excelImportFileTooLarge);
            return;
          }
          setState(() {
            _selectedFileName = name;
            _selectedBytes = bytes;
          });
        });
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.excelImportTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.excelImportUploadAction,
            isLoading: _uploading,
            onPressed: _canUpload ? _upload : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _buildQuizHeader(l10n),
          const SizedBox(height: AppSpacing.lg),
          _buildColumnsCard(l10n),
          const SizedBox(height: AppSpacing.lg),
          _buildTemplateSection(l10n),
          const SizedBox(height: AppSpacing.lg),
          AppSectionTitle(title: l10n.excelImportUploadSection),
          _buildDropZone(l10n),
        ],
      ),
    );
  }
}

class _ColumnChip extends StatelessWidget {
  const _ColumnChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentCool.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accentCool,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
