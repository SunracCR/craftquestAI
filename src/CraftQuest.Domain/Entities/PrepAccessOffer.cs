namespace CraftQuest.Domain.Entities;

public class PrepAccessOffer
{
    public Guid OfferId { get; set; }
    public Guid CatalogItemId { get; set; }
    public int DurationDays { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public bool IsFree { get; set; }
    public string? StoreProductId { get; set; }
    public bool IsActive { get; set; } = true;

    public PrepCatalogItem CatalogItem { get; set; } = null!;
}
