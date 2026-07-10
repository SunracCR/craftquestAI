import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:flutter/material.dart';

/// Fuerza a [AuthGate] a reevaluar la URL de entrada web tras consumirla.
class WebAuthEntryNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Vuelve al login: hace pop si hay pila; si la pantalla es la raíz (p. ej. enlace
/// web `/reset-password`), limpia la URL y reconstruye el AuthGate.
void returnToLogin(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }

  clearWebEntryDeepLinkUrl();
  if (getIt.isRegistered<WebAuthEntryNotifier>()) {
    getIt<WebAuthEntryNotifier>().refresh();
  }
}
