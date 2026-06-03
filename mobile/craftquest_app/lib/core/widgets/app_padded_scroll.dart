import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Margen fijo alrededor del área con scroll (no añade hueco extra al desplazar).
EdgeInsets appPagePadding(
  BuildContext context, {
  bool top = true,
  bool bottom = true,
}) {
  final view = MediaQuery.viewPaddingOf(context);
  final safe = MediaQuery.paddingOf(context);
  // Margen extra a la derecha para que el contenido no quede bajo la scrollbar.
  const scrollbarGutter = 12.0;
  return EdgeInsets.only(
    left: AppSpacing.md + view.left,
    top: top ? AppSpacing.md : 0,
    right: AppSpacing.md + view.right + scrollbarGutter,
    bottom: bottom ? AppSpacing.lg + safe.bottom : 0,
  );
}

/// Envuelve listas / scroll con [appPagePadding].
class AppPaddedScrollBody extends StatelessWidget {
  const AppPaddedScrollBody({
    super.key,
    required this.child,
    this.includeTop = true,
    this.includeBottom = true,
  });

  final Widget child;
  final bool includeTop;
  final bool includeBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: appPagePadding(
        context,
        top: includeTop,
        bottom: includeBottom,
      ),
      child: child,
    );
  }
}
