import 'package:flutter/foundation.dart';

/// Avisa a Home/Perfil de que hubo un checkout y deben recargar billing/plan.
class CheckoutRefreshNotifier extends ChangeNotifier {
  void notifyCheckoutCompleted() {
    notifyListeners();
  }
}
