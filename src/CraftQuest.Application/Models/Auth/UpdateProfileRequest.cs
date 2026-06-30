namespace CraftQuest.Application.Models.Auth;

public sealed class UpdateProfileRequest
{
    public string? DisplayName { get; set; }
    public string? AvatarId { get; set; }
    public string? PreferredLanguage { get; set; }
    public DateOnly? DateOfBirth { get; set; }
}
