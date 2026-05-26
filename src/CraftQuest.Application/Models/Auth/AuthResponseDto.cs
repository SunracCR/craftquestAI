namespace CraftQuest.Application.Models.Auth;

public sealed class AuthResponseDto
{
    public required AuthTokensDto Tokens { get; init; }
    public required UserProfileDto User { get; init; }
}
