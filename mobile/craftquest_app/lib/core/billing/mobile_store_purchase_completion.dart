import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Completa la compra en StoreKit/Play con límite de tiempo para no bloquear la UI.
Future<void> completeMobileStorePurchaseIfNeeded(
  PurchaseDetails purchase, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (!purchase.pendingCompletePurchase) {
    return;
  }

  await InAppPurchase.instance
      .completePurchase(purchase)
      .timeout(timeout);
}
