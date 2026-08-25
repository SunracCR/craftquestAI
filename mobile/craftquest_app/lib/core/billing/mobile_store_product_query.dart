import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _storeAvailabilityTimeout = Duration(seconds: 10);
const _storeQueryTimeout = Duration(seconds: 15);

String normalizeStoreProductId(String productId) => productId.trim();

bool storeProductIdsMatch(String left, String right) =>
    normalizeStoreProductId(left).toLowerCase() ==
    normalizeStoreProductId(right).toLowerCase();

ProductDetails? pickStoreProduct(
  Iterable<ProductDetails> products,
  String productId,
) {
  for (final product in products) {
    if (storeProductIdsMatch(product.id, productId)) {
      return product;
    }
  }
  return null;
}

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
  final normalizedIds = productIds
      .map(normalizeStoreProductId)
      .where((id) => id.isNotEmpty)
      .toSet();
  if (normalizedIds.isEmpty) {
    return ProductDetailsResponse(productDetails: [], notFoundIDs: const []);
  }

  final response = await InAppPurchase.instance
      .queryProductDetails(normalizedIds)
      .timeout(
        timeout,
        onTimeout: () => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: normalizedIds.toList(),
        ),
      );
  if (kDebugMode) {
    debugPrint(
      '[IAP] queryProductDetails requested=${normalizedIds.join(', ')}',
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

Future<ProductDetails?> findMobileStoreProduct(
  String productId, {
  Iterable<ProductDetails> cachedProducts = const [],
}) async {
  final normalizedId = normalizeStoreProductId(productId);
  if (normalizedId.isEmpty) {
    return null;
  }

  final cached = pickStoreProduct(cachedProducts, normalizedId);
  if (cached != null) {
    return cached;
  }

  for (var attempt = 0; attempt < 2; attempt++) {
    final response = await queryMobileStoreProducts({normalizedId});
    final product = pickStoreProduct(response.productDetails, normalizedId);
    if (product != null) {
      return product;
    }
    if (attempt == 0 && response.error == null) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      continue;
    }
    break;
  }

  return null;
}
