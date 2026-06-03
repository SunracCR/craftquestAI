import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_image_viewer.dart';
import 'package:craftquest_app/core/widgets/craft_quest_network_image.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Imagen en red con botón de lupa para verla a pantalla completa.
class AppZoomableNetworkImage extends StatelessWidget {
  const AppZoomableNetworkImage({
    super.key,
    required this.imageUrl,
    this.height = AppMediaDisplay.questionImageHeight,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.onNetworkError,
  });

  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final VoidCallback? onNetworkError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final image = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CraftQuestNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            errorBuilder: (_, __, ___) {
              final callback = onNetworkError;
              if (callback != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  callback();
                });
              }
              return const SizedBox.shrink();
            },
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.zoom_in, size: 20),
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: l10n.viewFullImageAction,
                onPressed: () =>
                    AppImageViewer.show(context, imageUrl: imageUrl),
              ),
            ),
          ),
        ],
      ),
    );

    final radius = borderRadius;
    if (radius == null) return image;

    return ClipRRect(borderRadius: radius, child: image);
  }
}
