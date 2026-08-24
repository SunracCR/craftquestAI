import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Completa la compra en StoreKit/Play con límite de tiempo.
/// Nunca lanza: un fallo aquí no debe bloquear el refresh post-pago.
Future<bool> completeMobileStorePurchaseIfNeeded(
  PurchaseDetails purchase, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (!purchase.pendingCompletePurchase) {
    return true;
  }

  try {
    await InAppPurchase.instance
        .completePurchase(purchase)
        .timeout(timeout);
    return true;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint(
        '[IAP] completePurchase failed product=${purchase.productID} error=$e',
      );
      debugPrint('$st');
    }
    return false;
  }
}
