import 'package:in_app_purchase/in_app_purchase.dart';

/// Estado observable del flujo de compra en tienda (Apple / Google Play).
sealed class PurchaseFlowState {
  const PurchaseFlowState();
}

class PurchaseIdle extends PurchaseFlowState {
  const PurchaseIdle();
}

class PurchasePreparing extends PurchaseFlowState {
  const PurchasePreparing();
}

class PurchaseAwaitingStore extends PurchaseFlowState {
  const PurchaseAwaitingStore();
}

class PurchaseDeferred extends PurchaseFlowState {
  const PurchaseDeferred();
}

class PurchaseVerifying extends PurchaseFlowState {
  const PurchaseVerifying();
}

class PurchaseSucceeded extends PurchaseFlowState {
  const PurchaseSucceeded(this.result);

  final PurchaseFlowResult result;
}

class PurchaseFailed extends PurchaseFlowState {
  const PurchaseFailed(this.reason, {this.message});

  final PurchaseFailureReason reason;
  final String? message;
}

enum PurchaseFailureReason {
  storeUnavailable,
  productNotFound,
  storeError,
  verificationFailed,
  timeout,
  cancelled,
  duplicateInFlight,
}

enum PurchaseProductKind {
  subscription,
  aiCredits,
  prepPlus,
}

sealed class PurchaseFlowResult {
  const PurchaseFlowResult(this.kind);

  final PurchaseProductKind kind;
}

class SubscriptionPurchaseResult extends PurchaseFlowResult {
  const SubscriptionPurchaseResult({required this.planCode})
      : super(PurchaseProductKind.subscription);

  final String planCode;
}

class AiCreditsPurchaseResult extends PurchaseFlowResult {
  const AiCreditsPurchaseResult({required this.creditsGranted})
      : super(PurchaseProductKind.aiCredits);

  final int creditsGranted;
}

class PrepPlusPurchaseResult extends PurchaseFlowResult {
  const PrepPlusPurchaseResult() : super(PurchaseProductKind.prepPlus);
}

/// Parámetros para iniciar una compra en tienda nativa.
class StorePurchaseRequest {
  const StorePurchaseRequest({
    required this.kind,
    required this.productId,
    this.product,
    this.billingCycle,
    this.catalogItemId,
    this.offerId,
    this.referralCode,
    this.userInitiated = true,
  });

  final PurchaseProductKind kind;
  final String productId;
  final ProductDetails? product;
  final String? billingCycle;
  final String? catalogItemId;
  final String? offerId;
  final String? referralCode;
  final bool userInitiated;
}
