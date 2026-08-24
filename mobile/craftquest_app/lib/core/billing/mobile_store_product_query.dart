import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _storeAvailabilityTimeout = Duration(seconds: 10);
const _storeQueryTimeout = Duration(seconds: 15);

/// Indica si la tienda nativa está disponible y lo registra en debug.
Future<bool> isMobileStoreAvailable({
  Duration timeout = _storeAvailabilityTimeout,
}) async {
  final available = await InAppPurchase.instance
      .isAvailable()
      .timeout(timeout, onTimeout: () => false);
  if (kDebugMode) {
    debugPrint(
      '[IAP] storeAvailable=$available platform=${defaultTargetPlatform.name}',
    );
  }
  return available;
}

/// Consulta productos IAP y registra en debug qué devolvió StoreKit / Play Billing.
Future<ProductDetailsResponse> queryMobileStoreProducts(
  Set<String> productIds, {
  Duration timeout = _storeQueryTimeout,
}) async {
  final response = await InAppPurchase.instance
      .queryProductDetails(productIds)
      .timeout(
        timeout,
        onTimeout: () => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: productIds.toList(),
        ),
      );
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
