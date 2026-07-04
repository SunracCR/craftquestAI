import 'package:craftquest_app/features/billing/data/models/billing_models.dart';
import 'package:flutter/foundation.dart';

/// Avisa a Home/Perfil de que hubo un checkout y deben recargar billing/plan.
class CheckoutRefreshNotifier extends ChangeNotifier {
  UserBillingModel? latestBilling;
  bool lastAffectsHomeTab = true;

  void notifyCheckoutCompleted({
    UserBillingModel? billing,
    bool affectsHomeTab = true,
  }) {
    lastAffectsHomeTab = affectsHomeTab;
    if (billing != null) {
      latestBilling = billing;
    }
    notifyListeners();
  }
}
