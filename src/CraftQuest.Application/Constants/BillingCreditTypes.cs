namespace CraftQuest.Application.Constants;

/// <summary>
/// Tipos de saldo en <c>billing.CreditLedger</c>.
/// </summary>
public static class BillingCreditTypes
{
    /// <summary>Créditos IA del cupo del plan (reinicio mensual calendario o ciclo de suscripción).</summary>
    public const string AiPlan = "ai";

    /// <summary>Créditos IA comprados en paquetes (no expiran ni se reinician).</summary>
    public const string AiPurchased = "ai_purchased";

    public const string ShareCode = "share_code";
}
