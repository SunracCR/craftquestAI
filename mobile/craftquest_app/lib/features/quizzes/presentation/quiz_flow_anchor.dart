import 'package:flutter/material.dart';

/// Marca la pantalla desde la que se inició la creación de un cuestionario
/// para volver a ella tras importar, añadir preguntas o generar con IA.
abstract final class QuizFlowAnchor {
  static Route<dynamic>? _anchorRoute;

  static void mark(BuildContext context) {
    _anchorRoute = ModalRoute.of(context);
  }

  static bool get hasAnchor => _anchorRoute != null;

  static void returnToAnchor(BuildContext context) {
    final anchor = _anchorRoute;
    if (anchor == null || !context.mounted) return;

    final navigator = Navigator.of(context);
    var found = false;
    navigator.popUntil((route) {
      if (route == anchor) found = true;
      return found || route.isFirst;
    });
    _anchorRoute = null;
  }

  static void clear() {
    _anchorRoute = null;
  }
}
