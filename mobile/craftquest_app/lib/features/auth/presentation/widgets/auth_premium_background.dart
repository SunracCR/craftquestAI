import 'package:craftquest_app/core/assets/auth_assets.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Fondo de autenticación (imagen + velo para legibilidad del formulario).
class AuthPremiumBackground extends StatelessWidget {
  const AuthPremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AuthAssets.loginBackground,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const _GradientFallbackBackground(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.35),
                AppColors.background.withValues(alpha: 0.72),
                AppColors.background.withValues(alpha: 0.88),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GradientFallbackBackground extends StatelessWidget {
  const _GradientFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF15262C),
            AppColors.background,
            Color(0xFF1E333B),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

/// Tarjeta de formulario con borde sutil y elevación premium.
class AuthPremiumCard extends StatelessWidget {
  const AuthPremiumCard({
    super.key,
    required this.child,
    this.dense = false,
  });

  final Widget child;

  /// Menos padding interno (p. ej. login sin scroll vertical).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final padding = dense
        ? const EdgeInsets.fromLTRB(20, 16, 20, 16)
        : const EdgeInsets.fromLTRB(24, 28, 24, 24);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusMd + 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.98),
            const Color(0xFF2A3840).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
