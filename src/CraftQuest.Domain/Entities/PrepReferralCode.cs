namespace CraftQuest.Domain.Entities;

public class PrepReferralCode
{
    public Guid ReferralCodeId { get; set; }
    public string Code { get; set; } = string.Empty;
    public Guid CatalogItemId { get; set; }
    public Guid ReferrerUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsActive { get; set; } = true;

    public PrepCatalogItem CatalogItem { get; set; } = null!;
    public User ReferrerUser { get; set; } = null!;
}
