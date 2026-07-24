import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_storage_bootstrap.dart';
import 'package:flutter/material.dart';

class OfflineQuizActionsPanel extends StatelessWidget {
  const OfflineQuizActionsPanel({
    super.key,
    required this.isDownloaded,
    required this.isDownloading,
    required this.canDownloadOffline,
    required this.isPlatformSupported,
    required this.onDownload,
    required this.onPracticeOffline,
    required this.onRemoveDownload,
    required this.onUpgradePrompt,
  });

  final bool isDownloaded;
  final bool isDownloading;
  final bool canDownloadOffline;
  final bool isPlatformSupported;
  final VoidCallback onDownload;
  final VoidCallback onPracticeOffline;
  final VoidCallback onRemoveDownload;
  final VoidCallback onUpgradePrompt;

  @override
  Widget build(BuildContext context) {
    if (!isPlatformSupported) {
      return AppSectionCard(
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                OfflinePlatformSupport.unsupportedPanelMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (!canDownloadOffline) {
      return AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Practica sin conexión',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Descarga este cuestionario en tu dispositivo con un plan de pago.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: 'Ver planes',
              icon: Icons.lock_outline_rounded,
              onPressed: onUpgradePrompt,
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      return AppSectionCard(
        variant: AppCardVariant.highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.offline_pin_rounded,
                  color: AppColors.accentMint.withValues(alpha: 0.95),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Disponible sin conexión en este dispositivo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Practicar offline',
              icon: Icons.play_arrow_rounded,
              onPressed: onPracticeOffline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: isDownloading ? 'Actualizando...' : 'Actualizar',
                    isLoading: isDownloading,
                    onPressed: isDownloading ? null : onDownload,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Quitar descarga',
                    onPressed: isDownloading ? null : onRemoveDownload,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Practica sin conexión',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Descarga este cuestionario en tu dispositivo para usarlo sin internet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: isDownloading ? 'Descargando...' : 'Descargar en este dispositivo',
            icon: Icons.download_for_offline_rounded,
            isLoading: isDownloading,
            onPressed: isDownloading ? null : onDownload,
          ),
        ],
      ),
    );
  }
}
