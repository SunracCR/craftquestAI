/// Reglas de acceso según plan de facturación.
abstract final class BillingPlanAccess {
  static bool isPaidPlan(String? planCode) {
    if (planCode == null || planCode.isEmpty) {
      return false;
    }
    return planCode.toLowerCase() != 'free';
  }

  static bool canBuyAiCreditPacks(String? planCode) => isPaidPlan(planCode);

  static bool canExportQuizPdf(String? planCode) => isPaidPlan(planCode);

  static bool canDownloadOffline(String? planCode) => isPaidPlan(planCode);
}
