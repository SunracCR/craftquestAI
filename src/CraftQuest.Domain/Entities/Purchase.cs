namespace CraftQuest.Domain.Entities;

public class Purchase
{
    public Guid PurchaseId { get; set; }
    public Guid UserId { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductType { get; set; } = "subscription";
    public string ProviderCode { get; set; } = string.Empty;
    public string? ProviderTransactionId { get; set; }
    public decimal? Amount { get; set; }
    public string? CurrencyCode { get; set; }
    public string Status { get; set; } = "pending";
    public DateTime? PurchasedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
