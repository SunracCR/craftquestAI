import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';

/// Reglas puras para decidir si un evento terminal de la tienda debe ignorarse
/// cuando el mismo lote incluye una compra válida o hay verificación en curso.
abstract final class StorePurchaseBatchPolicy {
  static bool batchContainsSuccessfulPurchase(
    Iterable<String> productIds,
    String targetProductId,
  ) =>
      productIds.any((id) => storeProductIdsMatch(id, targetProductId));

  /// Un rechazo confirmado no se ignora porque la verificación ya empezó.
  /// Solo se ignora si el mismo lote trae un cobro real del mismo producto:
  /// ese cobro es la confirmación y el cancel que viaja con él es ruido.
  static bool shouldIgnoreTerminalFailure({
    required bool matchesActiveRequest,
    required bool batchHasSuccessfulForProduct,
  }) {
    if (!matchesActiveRequest) {
      return false;
    }
    return batchHasSuccessfulForProduct;
  }

  /// Solo una compra nueva, con token, del producto que el usuario acaba de
  /// pedir puede mostrar "Confirmando tu acceso…". Las restauradas (historial
  /// al reanudar la app) y los eventos vacíos de la hoja de Play no.
  static bool drivesActivePurchaseUi({
    required bool inFlight,
    required bool productMatchesActiveRequest,
    required bool isRestored,
    required bool hasProductId,
    required bool hasPurchaseToken,
  }) {
    if (!inFlight || !productMatchesActiveRequest) {
      return false;
    }
    if (isRestored || !hasProductId || !hasPurchaseToken) {
      return false;
    }
    return true;
  }

  /// Un cancel/error de la hoja de Play tiene que cerrar la compra activa
  /// aunque el listener lo haya marcado como background (resume, pending).
  static bool shouldSurfaceTerminalFailure({
    required bool listenerMarkedBackground,
    required bool inFlight,
    required bool waitingForStoreOutcome,
    required bool productIdEmpty,
    required bool productMatchesActiveRequest,
  }) {
    if (!listenerMarkedBackground) {
      return true;
    }
    if (!inFlight || !waitingForStoreOutcome) {
      return false;
    }
    if (productIdEmpty) {
      return true;
    }
    return productMatchesActiveRequest;
  }
}
