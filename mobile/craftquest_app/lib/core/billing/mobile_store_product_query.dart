import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Indica si la tienda nativa está disponible y lo registra en debug.
Future<bool> isMobileStoreAvailable() async {
  final available = await InAppPurchase.instance.isAvailable();
  if (kDebugMode) {
    debugPrint(
      '[IAP] storeAvailable=$available platform=${defaultTargetPlatform.name}',
    );
  }
  return available;
}

/// Consulta productos IAP y registra en debug qué devolvió StoreKit / Play Billing.
Future<ProductDetailsResponse> queryMobileStoreProducts(
  Set<String> productIds,
) async {
  final response =
      await InAppPurchase.instance.queryProductDetails(productIds);
  if (kDebugMode) {
    debugPrint(
      '[IAP] queryProductDetails requested=${productIds.join(', ')}',
    );
    debugPrint(
      '[IAP] found=${response.productDetails.map((p) => p.id).join(', ')}',
    );
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        '[IAP] notFound=${response.notFoundIDs.join(', ')} '
        '(Apple/Play no expuso estos IDs; revisa App Store Connect / Play Console)',
      );
    }
    if (response.error != null) {
      debugPrint(
        '[IAP] query error: ${response.error!.source} '
        '${response.error!.code} ${response.error!.message}',
      );
    }
  }
  return response;
}

Future<ProductDetails?> findMobileStoreProduct(String productId) async {
  final response = await queryMobileStoreProducts({productId});
  for (final product in response.productDetails) {
    if (product.id == productId) {
      return product;
    }
  }
  return null;
}
