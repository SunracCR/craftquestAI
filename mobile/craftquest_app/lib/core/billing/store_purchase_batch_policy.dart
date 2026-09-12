import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';

/// Reglas puras para decidir si un evento terminal de la tienda debe ignorarse
/// cuando el mismo lote incluye una compra válida o hay verificación en curso.
abstract final class StorePurchaseBatchPolicy {
  static bool batchContainsSuccessfulPurchase(
    Iterable<String> productIds,
    String targetProductId,
  ) =>
      productIds.any((id) => storeProductIdsMatch(id, targetProductId));

  static bool shouldIgnoreTerminalFailure({
    required bool matchesActiveRequest,
    required bool batchHasSuccessfulForProduct,
    required bool isVerifyingOrSucceeded,
    required bool hasInFlightVerificationForProduct,
  }) {
    if (!matchesActiveRequest) {
      return false;
    }
    if (batchHasSuccessfulForProduct) {
      return true;
    }
    if (isVerifyingOrSucceeded) {
      return true;
    }
    if (hasInFlightVerificationForProduct) {
      return true;
    }
    return false;
  }
}
