import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Transacciones de StoreKit 2 que Apple aún no ha recibido como "finished".
///
/// Si quedan abiertas, `buyConsumable` falla con
/// `storekit_duplicate_product_object` aunque en el historial de CraftQuest
/// no aparezca nada pendiente.
Future<List<PurchaseDetails>> listIosUnfinishedStorePurchases() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return const [];
  }

  if (!InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
    return const [];
  }

  try {
    final transactions = await SK2Transaction.unfinishedTransactions();
    return transactions
        .map(_toPurchaseDetails)
        .whereType<PurchaseDetails>()
        .toList();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[IAP] unfinishedTransactions failed: $e');
      debugPrint('$st');
    }
    return const [];
  }
}

PurchaseDetails? _toPurchaseDetails(SK2Transaction transaction) {
  final receipt = transaction.receiptData;
  if (receipt == null || receipt.isEmpty) {
    return null;
  }

  return SK2PurchaseDetails(
    productID: transaction.productId,
    purchaseID: transaction.id,
    verificationData: PurchaseVerificationData(
      localVerificationData: transaction.jsonRepresentation ?? '',
      serverVerificationData: receipt,
      source: kIAPSource,
    ),
    transactionDate: transaction.purchaseDate,
    status: PurchaseStatus.purchased,
    appAccountToken: transaction.appAccountToken,
  );
}

bool isIosDuplicateUnfinishedStoreError(PlatformException error) {
  final code = error.code.toLowerCase();
  final message = (error.message ?? '').toLowerCase();
  return code.contains('duplicate') ||
      code == 'storekit_duplicate_product_object' ||
      message.contains('pending transaction for the same product');
}
