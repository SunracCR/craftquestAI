import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _googleLogoAsset = 'assets/icons/oauth/google_g.svg';

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

