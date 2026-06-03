namespace CraftQuest.Application.Models.Billing;

/// <summary>Resultado normalizado tras validar una suscripción en Google Play o App Store.</summary>
public sealed class MobileStoreSubscriptionDetails
{
    public required string PlanCode { get; init; }
    public required string BillingCycle { get; init; }
    public required string ProviderSubscriptionId { get; init; }
    public required bool IsActive { get; init; }
    public bool AutoRenewEnabled { get; init; } = true;
    public DateTime? PeriodEnd { get; init; }
    public string? LatestTransactionId { get; init; }
}
