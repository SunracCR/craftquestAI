namespace CraftQuest.Domain.Entities;

public class AuthProvider
{
    public Guid AuthProviderId { get; set; }
    public Guid UserId { get; set; }
    public string ProviderCode { get; set; } = string.Empty;
    public string ProviderSubject { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
