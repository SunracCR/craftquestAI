import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Fondo atmosférico para pantallas de autenticación (gradiente + halos).
class AuthPremiumBackground extends StatelessWidget {
  const AuthPremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
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
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowOrb(
              size: 180,
              color: AppColors.accentCool.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            left: MediaQuery.sizeOf(context).width * 0.5 - 1,
            child: _GlowOrb(
              size: 120,
              color: AppColors.accentGold.withValues(alpha: 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de formulario con borde sutil y elevación premium.
class AuthPremiumCard extends StatelessWidget {
  const AuthPremiumCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: child,
      ),
    );
  }
}
