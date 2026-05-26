import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudyMaterialLibraryCard extends StatelessWidget {
  const StudyMaterialLibraryCard({
    super.key,
    required this.title,
    required this.fileType,
    required this.statusLabel,
    required this.statusColor,
    required this.uploadedLabel,
    required this.expiryLabel,
    required this.showReviewBadge,
    required this.reviewLabel,
    this.generationChipLabel,
    this.generationChipColor,
    required this.isDeleting,
    required this.deleteTooltip,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String fileType;
  final String statusLabel;
  final Color statusColor;
  final String uploadedLabel;
  final String expiryLabel;
  final bool showReviewBadge;
  final String reviewLabel;
  final String? generationChipLabel;
  final Color? generationChipColor;
  final bool isDeleting;
  final String deleteTooltip;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileVisual = _fileVisual(fileType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceHighlight,
                AppColors.surface.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: AppColors.accentCool.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        fileVisual.background,
                        fileVisual.background.withValues(alpha: 0.55),
                      ],
                    ),
                    border: Border.all(
                      color: fileVisual.foreground.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    fileVisual.icon,
                    color: fileVisual.foreground,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusChip(
                            label: statusLabel,
                            color: statusColor,
                          ),
                        ],
                      ),
                      if (generationChipLabel != null && generationChipColor != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _StatusChip(
                          label: generationChipLabel!,
                          color: generationChipColor!,
                          icon: generationChipColor == AppColors.accentMint
                              ? Icons.fact_check_outlined
                              : Icons.auto_awesome_rounded,
                        ),
                      ],
                      if (showReviewBadge) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _StatusChip(
                          label: reviewLabel,
                          color: AppColors.accentGold,
                          icon: Icons.edit_note_rounded,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _MetaRow(
                        icon: Icons.upload_rounded,
                        label: uploadedLabel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _MetaRow(
                        icon: Icons.schedule_rounded,
                        label: expiryLabel,
                        iconColor: AppColors.accentGold.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  children: [
                    _IconActionButton(
                      tooltip: deleteTooltip,
                      icon: Icons.delete_outline_rounded,
                      iconColor: AppColors.error.withValues(alpha: 0.9),
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                      isLoading: isDeleting,
                      onPressed: isDeleting ? null : onDelete,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.accentWarm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static _FileVisual _fileVisual(String fileType) {
    if (fileType == 'docx') {
      return const _FileVisual(
        icon: Icons.description_rounded,
        foreground: AppColors.accentSky,
        background: Color(0xFF1E3A52),
      );
    }
    return const _FileVisual(
      icon: Icons.picture_as_pdf_rounded,
      foreground: Color(0xFFFF8A7A),
      background: Color(0xFF3D2528),
    );
  }
}

class _FileVisual {
  const _FileVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onPressed,
    this.isLoading = false,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner informativo de retención en la biblioteca.
class StudyMaterialLibraryRetentionBanner extends StatelessWidget {
  const StudyMaterialLibraryRetentionBanner({
    super.key,
    required this.hint,
    required this.materialCountLabel,
  });

  final String hint;
  final String materialCountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.accentGold.withValues(alpha: 0.14),
            AppColors.accentCool.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.folder_special_rounded,
              color: AppColors.accentGold,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materialCountLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentWarm,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Utilidades de etiquetas para la biblioteca.
abstract final class StudyMaterialLibraryLabels {
  static String statusLabel(AppLocalizations l10n, String processingStatus) {
    return switch (processingStatus) {
      'completed' => l10n.aiGenerationLibraryStatusReady,
      'processing' => l10n.aiGenerationLibraryStatusProcessing,
      'failed' => l10n.aiGenerationLibraryStatusFailed,
      'pending' => l10n.aiGenerationLibraryStatusPending,
      _ => processingStatus,
    };
  }

  static Color statusColor(String processingStatus) {
    return switch (processingStatus) {
      'completed' => AppColors.accentMint,
      'processing' => AppColors.accentCool,
      'failed' => AppColors.error,
      'pending' => AppColors.accentGold,
      _ => AppColors.textSecondary,
    };
  }

  static String uploadedLabel(
    AppLocalizations l10n,
    DateTime createdAt,
    DateFormat dateFormat,
  ) {
    return l10n.aiGenerationLibraryUploaded(
      dateFormat.format(createdAt.toLocal()),
    );
  }

  static String expiryLabel(
    AppLocalizations l10n,
    DateTime? retentionExpiresAt,
    DateFormat dateFormat,
  ) {
    if (retentionExpiresAt == null) {
      return '';
    }

    final expiresLocal = retentionExpiresAt.toLocal();
    final days = expiresLocal.difference(DateTime.now()).inDays;
    if (days >= 0 && days <= 14) {
      return l10n.aiGenerationLibraryExpiresInDays(days.clamp(0, 999));
    }

    return l10n.aiGenerationLibraryExpiresOn(
      dateFormat.format(expiresLocal),
    );
  }
}
