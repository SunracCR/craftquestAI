namespace CraftQuest.Application.Models.Billing;

public sealed class AiCreditPackDto
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public required int Credits { get; init; }
    public required decimal Price { get; init; }
    public required string CurrencyCode { get; init; }
    public string? GooglePlayProductId { get; init; }
    public string? AppStoreProductId { get; init; }
}

public sealed class PayPalCreateAiCreditOrderRequest
{
    public required string PackCode { get; init; }
}

public sealed class PayPalCaptureAiCreditOrderResponse
{
    public required string PackCode { get; init; }
    public required int CreditsGranted { get; init; }
    public required int AiCreditsBalance { get; init; }
    public required string Status { get; init; }
    public bool MockMode { get; init; }
}

public sealed class VerifyMobileAiCreditPurchaseRequest
{
    public required string Platform { get; init; }
    public required string ProductId { get; init; }
    public required string PurchaseToken { get; init; }
    public string? TransactionId { get; init; }
}

public sealed class VerifyMobileAiCreditPurchaseResponse
{
    public required string PackCode { get; init; }
    public required int CreditsGranted { get; init; }
    public required int AiCreditsBalance { get; init; }
    public required string Status { get; init; }
    public bool MockMode { get; init; }
}
