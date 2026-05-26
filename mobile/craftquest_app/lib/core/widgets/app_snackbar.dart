import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/network/api_error_mapper.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/features/billing/presentation/upgrade_plan_page.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Mensajes de feedback estandarizados (éxito verde / error rojo).
extension AppSnackBar on BuildContext {
  void showSuccessSnackBar(String message) {
    _showFeedbackSnackBar(
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  void showErrorSnackBar(String message) {
    _showFeedbackSnackBar(
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
    );
  }

  void showInfoSnackBar(String message) {
    _showFeedbackSnackBar(
      message: message,
      backgroundColor: AppColors.surfaceHighlight,
      icon: Icons.info_outline_rounded,
    );
  }

  void showDioErrorSnackBar(DioException error) {
    final l10n = AppLocalizations.of(this)!;
    final message = DioErrorMapper.map(error, l10n);
    if (DioErrorMapper.isConnectivityFailure(error)) {
      showInfoSnackBar(message);
      return;
    }

    if (ApiErrorMapper.isPlanLimitError(error)) {
      _showFeedbackSnackBar(
        message: message,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        actionLabel: l10n.upgradePlanAction,
        onAction: () {
          (rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(this))
              .hideCurrentSnackBar();
          Navigator.of(this).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const UpgradePlanPage(),
            ),
          );
        },
      );
      return;
    }

    showErrorSnackBar(message);
  }

  void _showFeedbackSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger =
        rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.onSnackBar, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.onSnackBar,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        elevation: 4,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.accentGold,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
