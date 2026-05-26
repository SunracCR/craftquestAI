import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:flutter/material.dart';

/// Opción de respuesta seleccionable (práctica) — sustituye chips sueltos.
class AppAnswerTile extends StatelessWidget {
  const AppAnswerTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.leading,
    this.mediaImageUrl,
    this.mediaHeight = 120,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? leading;

  /// URL de imagen mostrada dentro del recuadro (p. ej. opciones con imagen).
  final String? mediaImageUrl;
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent
        : AppColors.textSecondary.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mediaImageUrl != null)
                AppZoomableNetworkImage(
                  imageUrl: mediaImageUrl!,
                  height: mediaHeight,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  mediaImageUrl != null ? AppSpacing.sm : AppSpacing.sm + 2,
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
