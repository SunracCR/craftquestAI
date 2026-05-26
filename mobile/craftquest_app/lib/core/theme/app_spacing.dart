import 'package:flutter/material.dart';

/// Espaciado y medidas de layout — múltiplos de 8.
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double buttonHeight = 52;
  static const double iconButtonSize = 48;
  static const double fabClearance = 88;
  static const double bottomBarClearance = 96;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pageVertical = EdgeInsets.fromLTRB(md, md, md, xl);
  static const EdgeInsets listBottomWithFab = EdgeInsets.fromLTRB(md, md, md, fabClearance);
  static const EdgeInsets listBottom = EdgeInsets.fromLTRB(md, md, md, xl);
}
