namespace CraftQuest.Domain.Entities;

public class PrepReferralConversion
{
    public Guid PrepReferralConversionId { get; set; }
    public Guid ReferralCodeId { get; set; }
    public Guid ReferrerUserId { get; set; }
    public Guid BuyerUserId { get; set; }
    public Guid CatalogItemId { get; set; }
    public Guid PurchaseId { get; set; }
    public int RewardDaysGranted { get; set; } = 30;
    public DateTime CreatedAt { get; set; }

    public PrepReferralCode ReferralCode { get; set; } = null!;
    public User ReferrerUser { get; set; } = null!;
    public User BuyerUser { get; set; } = null!;
    public PrepCatalogItem CatalogItem { get; set; } = null!;
    public Purchase Purchase { get; set; } = null!;
}
