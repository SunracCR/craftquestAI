namespace CraftQuest.Application.Models.Billing;

public sealed class UpgradeablePlanDto
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public decimal? MonthlyPrice { get; init; }
    public decimal? AnnualPrice { get; init; }
    public string? GooglePlayProductId { get; init; }
    public string? GooglePlayAnnualProductId { get; init; }
    public string? AppStoreProductId { get; init; }
    public string? AppStoreAnnualProductId { get; init; }
    public bool RequiresContactSales { get; init; }
    public int MonthlyAiCredits { get; init; }
    public int MonthlyShareCodes { get; init; }
}

public sealed class PayPalCreateOrderRequest
{
    public required string PlanCode { get; init; }
    public string BillingCycle { get; init; } = "monthly";
}

public sealed class PayPalCreateOrderResponse
{
    public required Guid PurchaseId { get; init; }
    public required string OrderId { get; init; }
    public string? ApprovalUrl { get; init; }
    public bool MockMode { get; init; }
}

public sealed class PayPalCaptureOrderRequest
{
    public required string OrderId { get; init; }
}

public sealed class PayPalCaptureOrderResponse
{
    public required string PlanCode { get; init; }
    public required string Status { get; init; }
    public bool MockMode { get; init; }
}

public sealed class VerifyMobilePurchaseRequest
{
    public required string Platform { get; init; }
    public required string ProductId { get; init; }
    public required string PurchaseToken { get; init; }
    public string? TransactionId { get; init; }
}

public sealed class VerifyMobilePurchaseResponse
{
    public required string PlanCode { get; init; }
    public required string Status { get; init; }
    public string BillingCycle { get; init; } = "monthly";
    public DateTime? CurrentPeriodEnd { get; init; }
    public bool AutoRenewEnabled { get; init; } = true;
    public bool MockMode { get; init; }
}

public sealed class PayPalCreateSubscriptionRequest
{
    public required string PlanCode { get; init; }
    public string BillingCycle { get; init; } = "monthly";
}

public sealed class PayPalCreateSubscriptionResponse
{
    public required Guid PurchaseId { get; init; }
    public required string SubscriptionId { get; init; }
    public string? ApprovalUrl { get; init; }
    public bool MockMode { get; init; }
}

public sealed class PayPalActivateSubscriptionRequest
{
    public required string SubscriptionId { get; init; }
    public string? BillingCycle { get; init; }
}

public sealed class PayPalActivateSubscriptionResponse
{
    public required string PlanCode { get; init; }
    public required string Status { get; init; }
    public DateTime? CurrentPeriodEnd { get; init; }
    public bool AutoRenewEnabled { get; init; }
    public bool MockMode { get; init; }
}

public sealed class CancelAutoRenewResponse
{
    public required DateTime AccessUntil { get; init; }
    public bool AutoRenewEnabled { get; init; }

    /// <summary>paypal | google_play | app_store | manual_admin, etc.</summary>
    public string? ProviderCode { get; init; }

    /// <summary>True cuando la renovación solo puede gestionarse en la tienda (Google/Apple).</summary>
    public bool ManageInStore { get; init; }
}

public sealed class ReactivateAutoRenewResponse
{
    public bool AutoRenewEnabled { get; init; }
    public DateTime? NextRenewalAt { get; init; }
    public string? ProviderCode { get; init; }

    /// <summary>True cuando la reactivación del cobro solo puede hacerse en la tienda (Google/Apple).</summary>
    public bool ManageInStore { get; init; }

    /// <summary>
    /// PayPal real: la suscripción ya fue cancelada en PayPal; el usuario debe volver a suscribirse.
    /// </summary>
    public bool RequiresResubscribe { get; init; }
}

/// <summary>Resultado de intentar restaurar la renovación en el proveedor de pago.</summary>
public sealed class ProviderAutoRenewRestoreResult
{
    public bool CanUpdateBilling { get; init; }
    public bool ManageInStore { get; init; }
    public bool RequiresResubscribe { get; init; }
    public string? ProviderCode { get; init; }
}
