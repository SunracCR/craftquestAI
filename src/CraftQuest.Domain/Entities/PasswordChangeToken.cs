namespace CraftQuest.Domain.Entities;

public class PasswordChangeToken
{
    public Guid PasswordChangeTokenId { get; set; }
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public byte[] NewPasswordHash { get; set; } = [];
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UsedAt { get; set; }

    public User User { get; set; } = null!;
}
