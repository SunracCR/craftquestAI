namespace CraftQuest.Domain.Entities;

public class User
{
    public Guid UserId { get; set; }
    public string? ExternalSubject { get; set; }
    public string Email { get; set; } = string.Empty;
    public string EmailNormalized { get; set; } = string.Empty;
    public byte[]? PasswordHash { get; set; }
    public string? DisplayName { get; set; }
    public string? AvatarId { get; set; }
    public string? PreferredLanguage { get; set; }
    public string? PhotoUrl { get; set; }
    public string? CountryCode { get; set; }
    public string? PhoneNumber { get; set; }
    public string Status { get; set; } = "active";
    public DateTime? EmailVerifiedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public ICollection<UserRole> UserRoles { get; set; } = [];
    public ICollection<AuthProvider> AuthProviders { get; set; } = [];
}
