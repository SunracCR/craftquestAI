import 'package:flutter/material.dart';

/// Evita empujar rutas duplicadas por doble tap durante la animación de navegación.
abstract final class SafeNavigation {
  static DateTime? _lastPushAt;
  static const _minInterval = Duration(milliseconds: 450);

  static bool _tryAcquire() {
    final now = DateTime.now();
    if (_lastPushAt != null &&
        now.difference(_lastPushAt!) < _minInterval) {
      return false;
    }
    _lastPushAt = now;
    return true;
  }

  static Future<T?> pushPage<T>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    if (!_tryAcquire()) {
      return Future<T?>.value(null);
    }
    return Navigator.of(context)
        .push<T>(
          MaterialPageRoute<T>(
            settings: settings,
            builder: (_) => page,
          ),
        )
        .whenComplete(() {
      // Permite volver a entrar en cuanto se cierra la ruta (p. ej. atrás → practicar).
      _lastPushAt = null;
    });
  }
}
