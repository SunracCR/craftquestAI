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

  /// Prep+ u otro acceso activo al quiz permite descarga offline aunque el plan sea free.
  static bool canDownloadOfflineForQuiz({
    required String? planCode,
    required bool hasActiveQuizAccess,
  }) =>
      canDownloadOffline(planCode) || hasActiveQuizAccess;
}
