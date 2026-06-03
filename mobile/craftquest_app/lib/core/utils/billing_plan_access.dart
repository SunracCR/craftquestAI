/// Reglas de acceso según plan de facturación.
abstract final class BillingPlanAccess {
  static bool canBuyAiCreditPacks(String? planCode) {
    if (planCode == null || planCode.isEmpty) {
      return false;
    }
    return planCode.toLowerCase() != 'free';
  }
}
