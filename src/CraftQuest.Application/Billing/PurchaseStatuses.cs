namespace CraftQuest.Application.Billing;

public static class PurchaseStatuses
{
    /// <summary>Usuario aún no completó el checkout en la pasarela (PayPal).</summary>
    public const string AwaitingPayment = "awaiting_payment";

    /// <summary>Legacy / fulfillment en curso. No debe quedar así tras pago confirmado.</summary>
    public const string Pending = "pending";

    public const string Validated = "validated";
    public const string Cancelled = "cancelled";
    public const string Rejected = "rejected";
    public const string Refunded = "refunded";

    public static bool IsOpenCheckout(string? status) =>
        string.Equals(status, AwaitingPayment, StringComparison.OrdinalIgnoreCase)
        || string.Equals(status, Pending, StringComparison.OrdinalIgnoreCase);

    public static bool NeedsFulfillment(string? status) =>
        IsOpenCheckout(status);
}
