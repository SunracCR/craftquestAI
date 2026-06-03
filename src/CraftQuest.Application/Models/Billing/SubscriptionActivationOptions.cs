namespace CraftQuest.Application.Models.Billing;

public sealed class SubscriptionActivationOptions
{
    public string BillingCycle { get; init; } = "monthly";
    public bool AutoRenewEnabled { get; init; } = true;
    public bool CancelAtPeriodEnd { get; init; }
    public DateTime? PeriodStart { get; init; }
    public DateTime? PeriodEnd { get; init; }
    public DateTime? LastPaymentAt { get; init; }
}
