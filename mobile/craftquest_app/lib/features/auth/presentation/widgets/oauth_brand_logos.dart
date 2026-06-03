import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _googleLogoAsset = 'assets/icons/oauth/google_g.svg';
const _appleLogoAsset = 'assets/icons/oauth/apple_logo.svg';

/// Logotipo oficial de Google (SVG de marca).
class GoogleBrandLogo extends StatelessWidget {
  const GoogleBrandLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _googleLogoAsset,
        fit: BoxFit.contain,
        semanticsLabel: 'Google',
      ),
    );
  }
}

/// Logotipo Apple (SVG; `color` para adaptar al botón).
class AppleBrandLogo extends StatelessWidget {
  const AppleBrandLogo({
    super.key,
    this.size = 22,
    this.color = const Color(0xFF1A1A1A),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _appleLogoAsset,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        semanticsLabel: 'Apple',
      ),
    );
  }
}
