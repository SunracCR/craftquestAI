import 'package:flutter/foundation.dart';

/// Índice de la pestaña Prep+ en [MainShellPage].
const kPrepPlusTabIndex = 1;

/// Solicita cambio de pestaña en el shell principal (p. ej. tras retorno de PayPal).
class MainShellTabSignal extends ChangeNotifier {
  int? requestedTab;

  void requestTab(int index) {
    requestedTab = index;
    notifyListeners();
  }

  int? consume() {
    final tab = requestedTab;
    requestedTab = null;
    return tab;
  }
}
