namespace CraftQuest.Application.Models.Billing;

public sealed class UpgradeablePlanDto
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public decimal? MonthlyPrice { get; init; }
    public decimal? AnnualPrice { get; init; }
    public string? GooglePlayProductId { get; init; }
    public string? AppStoreProductId { get; init; }
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
    public bool MockMode { get; init; }
}
