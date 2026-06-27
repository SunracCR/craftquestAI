import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:flutter/material.dart';

/// Icono + etiqueta que encaja en botones estrechos (p. ej. dos CTAs en fila).
Widget _iconButtonLabelRow({
  required IconData icon,
  required String label,
  required double iconSize,
  Color? iconColor,
  TextStyle? textStyle,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: iconSize, color: iconColor),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    ],
  );
}

/// CTA principal a ancho completo.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const AppButtonLoader()
        : (icon != null
            ? _iconButtonLabelRow(icon: icon!, label: label, iconSize: 20)
            : Text(label));

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// CTA principal con gradiente melocotón → dorado (práctica, acciones destacadas).
class AppGradientPrimaryButton extends StatelessWidget {
  const AppGradientPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          gradient: LinearGradient(
            colors: enabled
                ? [AppColors.accent, AppColors.accentGold]
                : [
                    AppColors.accent.withValues(alpha: 0.45),
                    AppColors.accentGold.withValues(alpha: 0.45),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            child: Center(
              child: isLoading
                  ? const AppButtonLoader()
                  : (icon != null
                      ? _iconButtonLabelRow(
                          icon: icon!,
                          label: label,
                          iconSize: 22,
                          iconColor: AppColors.textPrimary,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.textPrimary),
                        )
                      : Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.textPrimary),
                        )),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción secundaria a ancho completo.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.accentColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const AppButtonLoader()
        : (icon != null
            ? _iconButtonLabelRow(icon: icon!, label: label, iconSize: 20)
            : Text(label));

    final tint = accentColor ?? AppColors.textPrimary;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: tint,
          side: BorderSide(color: tint.withValues(alpha: 0.65), width: 1.5),
          backgroundColor: tint.withValues(alpha: 0.08),
        ),
        child: child,
      ),
    );
  }
}

/// Botón terciario / enlace dentro de barras de acción.
class AppTextActionButton extends StatelessWidget {
  const AppTextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// Fila de acciones compactas (icono + etiqueta) para menús de pantalla.
class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.isLoading = false,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isLoading;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.accentCool;
    final bg = iconBackgroundColor ?? tint.withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        child: Opacity(
          opacity: isLoading ? 0.72 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tint,
                            ),
                          )
                        : Icon(icon, size: 22, color: tint),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (!isLoading)
                  Icon(
                    locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                    color: locked
                        ? AppColors.textSecondary
                        : tint.withValues(alpha: 0.85),
                    size: locked ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
