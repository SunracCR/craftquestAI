namespace CraftQuest.Domain.Entities;

public class DeviceToken
{
    public Guid DeviceTokenId { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime LastSeenAt { get; set; }

    public User User { get; set; } = null!;
}
