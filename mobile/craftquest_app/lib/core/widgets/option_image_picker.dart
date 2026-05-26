import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/utils/media_url_resolver.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:craftquest_app/features/media/data/media_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OptionImagePicker extends StatefulWidget {
  const OptionImagePicker({
    super.key,
    required this.label,
    this.mediaAssetId,
    this.onChanged,
  });

  final String label;
  final String? mediaAssetId;
  final ValueChanged<String?>? onChanged;

  @override
  State<OptionImagePicker> createState() => _OptionImagePickerState();
}

class _OptionImagePickerState extends State<OptionImagePicker> {
  final _picker = ImagePicker();
  String? _mediaAssetId;
  String? _previewUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(OptionImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaAssetId != widget.mediaAssetId) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _mediaAssetId = widget.mediaAssetId;
    _previewUrl = MediaUrlResolver.resolve(widget.mediaAssetId);
  }

  Future<void> _pickAndUpload() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name.isNotEmpty ? file.name : 'image.jpg';
      final asset = await getIt<MediaRepository>().uploadImage(
        bytes: bytes,
        fileName: fileName,
      );
      if (!mounted) return;
      setState(() {
        _mediaAssetId = asset.mediaAssetId;
        _previewUrl = MediaUrlResolver.resolveAbsolute(asset.url);
        _uploading = false;
      });
      widget.onChanged?.call(_mediaAssetId);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      context.showDioErrorSnackBar(e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      context.showErrorSnackBar(e.toString());
    }
  }

  void _removeImage() {
    setState(() {
      _mediaAssetId = null;
      _previewUrl = null;
    });
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        if (_previewUrl != null) ...[
          const SizedBox(height: 8),
          AppZoomableNetworkImage(
            imageUrl: _previewUrl!,
            height: 120,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
        ],
      ],
    );
  }
}
