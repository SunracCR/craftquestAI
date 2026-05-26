namespace CraftQuest.Application.Models.Auth;

public sealed class UserProfileDto
{
    public required Guid UserId { get; init; }
    public required string Email { get; init; }
    public string? DisplayName { get; init; }
    public string? AvatarId { get; init; }
    public string? PreferredLanguage { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }
}
