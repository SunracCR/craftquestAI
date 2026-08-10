import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_media_display.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_zoomable_network_image.dart';
import 'package:flutter/material.dart';

enum AnswerSelectionMode {
  single,
  multiple,
}

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
    this.mediaChild,
    this.mediaHeight = AppMediaDisplay.optionImageHeight,
    this.selectionMode = AnswerSelectionMode.single,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? leading;
  final String? mediaImageUrl;
  final Widget? mediaChild;
  final double mediaHeight;
  final AnswerSelectionMode selectionMode;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent
        : AppColors.textSecondary.withValues(alpha: 0.35);
    final selectionLeading = leading ?? _buildSelectionIcon();

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
              if (mediaChild != null)
                mediaChild!
              else if (mediaImageUrl != null)
                AppZoomableNetworkImage(
                  imageUrl: mediaImageUrl!,
                  height: mediaHeight,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  (mediaChild != null || mediaImageUrl != null)
                      ? AppSpacing.sm
                      : AppSpacing.sm + 2,
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: selectionLeading,
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIcon() {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    final icon = switch (selectionMode) {
      AnswerSelectionMode.single => selected
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked,
      AnswerSelectionMode.multiple => selected
          ? Icons.check_box
          : Icons.check_box_outline_blank,
    };

    return Icon(icon, color: color, size: 22);
  }
}
