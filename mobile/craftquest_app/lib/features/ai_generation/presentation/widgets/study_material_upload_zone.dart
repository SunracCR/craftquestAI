import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

/// Zona de subida premium (arrastrar / elegir archivo) para materiales IA.
class StudyMaterialUploadZone extends StatelessWidget {
  const StudyMaterialUploadZone({
    super.key,
    required this.l10n,
    required this.hasFile,
    required this.dragOver,
    required this.supportsFileDrop,
    required this.uploading,
    this.fileName,
    this.fileSizeLabel,
    this.fileIcon,
    required this.onPickFile,
    this.onChangeFile,
    this.onClearFile,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDragDone,
  });

  final AppLocalizations l10n;
  final bool hasFile;
  final bool dragOver;
  final bool supportsFileDrop;
  final bool uploading;
  final String? fileName;
  final String? fileSizeLabel;
  final IconData? fileIcon;
  final VoidCallback onPickFile;
  final VoidCallback? onChangeFile;
  final VoidCallback? onClearFile;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final void Function(List<XFile> files) onDragDone;

  @override
  Widget build(BuildContext context) {
    final zone = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 300),
      width: double.infinity,
      decoration: _decoration(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: hasFile
          ? _FileReadyContent(
              l10n: l10n,
              fileName: fileName!,
              fileSizeLabel: fileSizeLabel!,
              fileIcon: fileIcon ?? Icons.insert_drive_file_rounded,
              uploading: uploading,
              onChange: onChangeFile,
              onClear: onClearFile,
            )
          : _EmptyZoneContent(
              l10n: l10n,
              dragOver: dragOver,
              supportsFileDrop: supportsFileDrop,
              uploading: uploading,
              onPickFile: onPickFile,
            ),
    );

    if (!supportsFileDrop) {
      return zone;
    }

    return DropTarget(
      onDragEntered: (_) => onDragEntered(),
      onDragExited: (_) => onDragExited(),
      onDragDone: (details) => onDragDone(details.files),
      child: zone,
    );
  }

  BoxDecoration _decoration() {
    if (hasFile && !dragOver) {
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

    if (dragOver) {
      return BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.accentCool, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCool.withValues(alpha: 0.2),
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
        color: AppColors.accentCool.withValues(alpha: 0.28),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class StudyMaterialUploadHeader extends StatelessWidget {
  const StudyMaterialUploadHeader({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        gradient: const LinearGradient(
          colors: [AppColors.surfaceHighlight, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accentCool.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.accentCool,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiGenerationUploadTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.aiGenerationUploadSubtitle,
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
    );
  }
}

class StudyMaterialUploadConstraintChips extends StatelessWidget {
  const StudyMaterialUploadConstraintChips({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            const _FormatChip(icon: Icons.picture_as_pdf_outlined, label: 'PDF'),
            const _FormatChip(
              icon: Icons.description_outlined,
              label: 'DOCX',
            ),
            _FormatChip(
              icon: Icons.sd_storage_outlined,
              label: '${AiGenerationLimits.maxUploadMb} MB',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aiGenerationUploadLimitsHint(
            AiGenerationLimits.maxPagesPerMaterial,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class StudyMaterialUploadFormatGuide extends StatelessWidget {
  const StudyMaterialUploadFormatGuide({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSectionCard(
      variant: AppCardVariant.highlight,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          iconColor: AppColors.accentCool,
          collapsedIconColor: AppColors.textSecondary,
          title: Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 20,
                color: AppColors.accentCool.withValues(alpha: 0.95),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.aiGenerationUploadFormatGuideTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          children: [
            _GuideRow(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.error,
              text: l10n.aiGenerationUploadSelectableTextHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            _GuideRow(
              icon: Icons.straighten_rounded,
              iconColor: AppColors.accentGold,
              text: l10n.aiGenerationUploadLimitsHint(
                AiGenerationLimits.maxPagesPerMaterial,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _GuideRow(
              icon: Icons.call_split_rounded,
              iconColor: AppColors.accentCool,
              text: l10n.aiGenerationUploadLimitsSteps(
                AiGenerationLimits.maxPagesPerMaterial,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.errorMaterialNotSelectableTextGuidance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentCool.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentCool),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyZoneContent extends StatelessWidget {
  const _EmptyZoneContent({
    required this.l10n,
    required this.dragOver,
    required this.supportsFileDrop,
    required this.uploading,
    required this.onPickFile,
  });

  final AppLocalizations l10n;
  final bool dragOver;
  final bool supportsFileDrop;
  final bool uploading;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 52,
          color: dragOver ? AppColors.accentCool : AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          supportsFileDrop
              ? l10n.aiGenerationUploadHeroDrop
              : l10n.aiGenerationUploadHeroPick,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          supportsFileDrop
              ? l10n.aiGenerationUploadHeroPick
              : l10n.aiGenerationUploadHint,
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
          accentColor: AppColors.accentCool,
          onPressed: uploading ? null : onPickFile,
        ),
      ],
    );
  }
}

class _FileReadyContent extends StatelessWidget {
  const _FileReadyContent({
    required this.l10n,
    required this.fileName,
    required this.fileSizeLabel,
    required this.fileIcon,
    required this.uploading,
    this.onChange,
    this.onClear,
  });

  final AppLocalizations l10n;
  final String fileName;
  final String fileSizeLabel;
  final IconData fileIcon;
  final bool uploading;
  final VoidCallback? onChange;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
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
          label: l10n.aiGenerationUploadFileReady,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                fileIcon,
                size: 22,
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
          fileSizeLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.accentMint.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton.icon(
          onPressed: uploading ? null : onChange,
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          label: Text(l10n.aiGenerationUploadChangeFile),
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
        ),
        if (onClear != null) ...[
          TextButton(
            onPressed: uploading ? null : onClear,
            child: Text(
              l10n.aiGenerationUploadRemoveFile,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
