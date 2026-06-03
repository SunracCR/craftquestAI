import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Mantiene el botón premium visible; el GIS oficial queda debajo y recibe el clic
/// (única forma fiable de obtener idToken en web).
Widget buildOAuthGoogleWebButton({
  required Widget overlay,
  double height = 44,
  double borderRadius = 12,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          gsi_web.renderButton(
            configuration: gsi_web.GSIButtonConfiguration(
              type: gsi_web.GSIButtonType.standard,
              size: gsi_web.GSIButtonSize.large,
              theme: gsi_web.GSIButtonTheme.outline,
              shape: gsi_web.GSIButtonShape.rectangular,
              minimumWidth: 320,
            ),
          ),
          IgnorePointer(
            child: overlay,
          ),
        ],
      ),
    ),
  );
}
