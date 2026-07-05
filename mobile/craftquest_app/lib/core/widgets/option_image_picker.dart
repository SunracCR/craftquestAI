import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/utils/media_url_resolver.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:craftquest_app/features/media/data/media_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class OptionImagePicker extends StatefulWidget {
  const OptionImagePicker({
    super.key,
    required this.label,
    this.mediaAssetId,
    this.onChanged,
    this.previewHeight = AppMediaDisplay.optionImageHeight,
    this.showUploadSuccessSnackBar = true,
  });

  final String label;
  final String? mediaAssetId;
  final ValueChanged<String?>? onChanged;
  final double previewHeight;
  final bool showUploadSuccessSnackBar;

  @override
  State<OptionImagePicker> createState() => _OptionImagePickerState();
}

class _OptionImagePickerState extends State<OptionImagePicker> {
  final _picker = ImagePicker();
  String? _mediaAssetId;
  String? _previewUrl;
  Uint8List? _localPreviewBytes;
  bool _uploading = false;
  bool _networkPreviewFailed = false;

  static const _maxUploadBytes = 5_500_000;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(OptionImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaAssetId != widget.mediaAssetId) {
      final keepLocalPreview = _localPreviewBytes != null &&
          widget.mediaAssetId != null &&
          widget.mediaAssetId == _mediaAssetId;
      _syncFromWidget(clearLocalPreview: !keepLocalPreview);
    }
  }

  void _syncFromWidget({bool clearLocalPreview = true}) {
    _mediaAssetId = widget.mediaAssetId;
    _previewUrl = MediaUrlResolver.resolve(widget.mediaAssetId);
    if (clearLocalPreview) {
      _localPreviewBytes = null;
    }
    _networkPreviewFailed = false;
  }

  String _fileNameFromXFile(XFile file) {
    if (file.name.isNotEmpty) {
      return file.name;
    }
    final path = file.path;
    if (path.isNotEmpty) {
      final segments = path.split(RegExp(r'[/\\]'));
      final last = segments.isNotEmpty ? segments.last : '';
      if (last.isNotEmpty) {
        return last;
      }
    }
    return 'image.jpg';
  }

  Future<void> _pickAndUpload() async {
    final l10n = AppLocalizations.of(context)!;

    XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      if (code.contains('permission') || code.contains('denied')) {
        context.showErrorSnackBar(l10n.imagePickPermissionDenied);
      } else {
        context.showErrorSnackBar(l10n.imagePickFailed);
      }
      return;
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.imagePickFailed);
      return;
    }

    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.length > _maxUploadBytes) {
        setState(() => _uploading = false);
        context.showErrorSnackBar(l10n.imageTooLargeForUpload);
        return;
      }

      setState(() {
        _localPreviewBytes = bytes;
        _networkPreviewFailed = false;
      });

      final asset = await getIt<MediaRepository>().uploadImage(
        bytes: bytes,
        fileName: _fileNameFromXFile(file),
      );
      if (!mounted) return;
      setState(() {
        _mediaAssetId = asset.mediaAssetId;
        _previewUrl = MediaUrlResolver.resolveAbsolute(asset.url);
        _uploading = false;
      });
      widget.onChanged?.call(_mediaAssetId);
      if (!mounted) return;
      if (widget.showUploadSuccessSnackBar) {
        context.showSuccessSnackBar(l10n.imageAttachedSuccess);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Image upload failed: status=${e.response?.statusCode} '
          'type=${e.type} data=${e.response?.data}',
        );
      }
      if (!mounted) return;
      _clearAfterFailedUpload();
      context.showDioErrorSnackBar(e);
    } on FormatException catch (_) {
      if (!mounted) return;
      _clearAfterFailedUpload();
      context.showErrorSnackBar(l10n.imageUploadInvalidResponse);
    } catch (e) {
      if (!mounted) return;
      _clearAfterFailedUpload();
      context.showErrorSnackBar(
        DioErrorMapper.mapAny(e, AppLocalizations.of(context)!),
      );
    }
  }

  void _clearAfterFailedUpload() {
    setState(() {
      _uploading = false;
      _localPreviewBytes = null;
      _mediaAssetId = null;
      _previewUrl = null;
    });
    widget.onChanged?.call(null);
  }

  void _removeImage() {
    setState(() {
      _mediaAssetId = null;
      _previewUrl = null;
      _localPreviewBytes = null;
      _networkPreviewFailed = false;
    });
    widget.onChanged?.call(null);
  }

  Widget _buildPreview(AppLocalizations l10n) {
    if (_localPreviewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: SizedBox(
          height: widget.previewHeight,
          width: double.infinity,
          child: Image.memory(
            _localPreviewBytes!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }

    if (_previewUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppZoomableNetworkImage(
            imageUrl: _previewUrl!,
            height: widget.previewHeight,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            onNetworkError: () {
              if (!mounted || _networkPreviewFailed) return;
              setState(() => _networkPreviewFailed = true);
            },
          ),
          if (_networkPreviewFailed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.imagePreviewLoadFailed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPreview =
        _localPreviewBytes != null || (_previewUrl != null && _mediaAssetId != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined, size: 18),
              label: Text(l10n.attachImageAction),
            ),
            if (_mediaAssetId != null)
              IconButton(
                onPressed: _uploading ? null : _removeImage,
                icon: const Icon(Icons.close, size: 20),
                tooltip: l10n.removeImageAction,
                color: AppColors.textSecondary,
              ),
          ],
        ),
        if (hasPreview) ...[
          const SizedBox(height: 8),
          _buildPreview(l10n),
        ],
      ],
    );
  }
}
