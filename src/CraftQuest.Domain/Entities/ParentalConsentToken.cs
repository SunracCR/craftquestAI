namespace CraftQuest.Domain.Entities;

public class ParentalConsentToken
{
    public Guid ParentalConsentTokenId { get; set; }
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UsedAt { get; set; }

    public User User { get; set; } = null!;
}
