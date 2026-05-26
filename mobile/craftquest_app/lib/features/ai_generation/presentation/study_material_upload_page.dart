import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/ai_generation/data/study_material_repository.dart';
import 'package:craftquest_app/features/ai_generation/presentation/study_material_outline_page.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/study_material_upload_failure_panel.dart';
import 'package:craftquest_app/features/ai_generation/presentation/widgets/study_material_upload_zone.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudyMaterialUploadPage extends StatefulWidget {
  const StudyMaterialUploadPage({
    super.key,
    this.targetQuizId,
    this.targetQuizTitle,
  });

  final String? targetQuizId;
  final String? targetQuizTitle;

  @override
  State<StudyMaterialUploadPage> createState() => _StudyMaterialUploadPageState();
}

class _StudyMaterialUploadPageState extends State<StudyMaterialUploadPage> {
  final _repository = getIt<StudyMaterialRepository>();
  bool _uploading = false;
  bool _dragOver = false;

  String? _documentFileName;
  List<int>? _documentBytes;
  String? _uploadErrorMessage;
  String? _uploadErrorGuidance;

  bool get _supportsFileDrop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool get _hasSelectedFile =>
      _documentFileName != null && _documentBytes != null && _documentBytes!.isNotEmpty;

  void _clearSelectedFile() {
    setState(() {
      _documentFileName = null;
      _documentBytes = null;
    });
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForFileName(String name) {
    return name.toLowerCase().endsWith('.docx')
        ? Icons.description_outlined
        : Icons.picture_as_pdf_outlined;
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() {
      _documentFileName = file.name;
      _documentBytes = bytes;
      _uploadErrorMessage = null;
      _uploadErrorGuidance = null;
    });
  }

  void _handleDroppedFiles(List<XFile> files) {
    if (_uploading || files.isEmpty) return;

    final file = files.first;
    final name = file.name.toLowerCase();
    if (!name.endsWith('.pdf') && !name.endsWith('.docx')) {
      context.showErrorSnackBar(AppLocalizations.of(context)!.aiGenerationUploadHint);
      return;
    }
    file.readAsBytes().then((bytes) {
      if (!mounted) return;
      setState(() {
        _documentFileName = file.name;
        _documentBytes = bytes;
        _uploadErrorMessage = null;
        _uploadErrorGuidance = null;
      });
    });
  }

  void _handleUploadError(DioException error) {
    final l10n = AppLocalizations.of(context)!;
    final data = ApiErrorMapper.problemDetailsFrom(error);
    final message = data != null
        ? ApiErrorMapper.mapProblemDetails(data, l10n) ?? DioErrorMapper.map(error, l10n)
        : DioErrorMapper.map(error, l10n);
    final guidance = data != null
        ? ApiErrorMapper.mapMaterialUploadGuidance(data, l10n)
        : null;

    setState(() {
      _uploadErrorMessage = message;
      _uploadErrorGuidance = guidance;
    });

    if (guidance == null) {
      context.showErrorSnackBar(message);
    }
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    if (_documentBytes == null || _documentFileName == null) return;

    setState(() {
      _uploading = true;
      _uploadErrorMessage = null;
      _uploadErrorGuidance = null;
    });
    try {
      final upload = await _repository.upload(
        fileName: _documentFileName!,
        bytes: _documentBytes!,
      );

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => StudyMaterialOutlinePage(
            studyMaterialId: upload.studyMaterialId,
            targetQuizId: widget.targetQuizId,
            targetQuizTitle: widget.targetQuizTitle,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      _handleUploadError(e);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.aiGenerationFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.aiGenerationUploadTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.aiGenerationUploadAction,
            isLoading: _uploading,
            onPressed: _documentBytes != null && !_uploading ? _upload : null,
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
          if (_uploadErrorMessage != null && _uploadErrorGuidance != null) ...[
            StudyMaterialUploadFailurePanel(
              message: _uploadErrorMessage!,
              guidance: _uploadErrorGuidance!,
              onPickAnother: _pickDocument,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          StudyMaterialUploadHeader(l10n: l10n),
          const SizedBox(height: AppSpacing.md),
          StudyMaterialUploadConstraintChips(l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          if (!_hasSelectedFile) ...[
            StudyMaterialUploadFormatGuide(l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
          ],
          StudyMaterialUploadZone(
            l10n: l10n,
            hasFile: _hasSelectedFile,
            dragOver: _dragOver,
            supportsFileDrop: _supportsFileDrop,
            uploading: _uploading,
            fileName: _documentFileName,
            fileSizeLabel: _hasSelectedFile
                ? _formatFileSize(_documentBytes!.length)
                : null,
            fileIcon: _documentFileName != null
                ? _iconForFileName(_documentFileName!)
                : null,
            onPickFile: _pickDocument,
            onChangeFile: _pickDocument,
            onClearFile: _clearSelectedFile,
            onDragEntered: () => setState(() => _dragOver = true),
            onDragExited: () => setState(() => _dragOver = false),
            onDragDone: (files) {
              setState(() => _dragOver = false);
              _handleDroppedFiles(files);
            },
          ),
        ],
      ),
    );
  }
}
