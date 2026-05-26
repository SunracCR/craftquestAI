namespace CraftQuest.Application.Models.Auth;

public sealed class AuthTokensDto
{
    public required string AccessToken { get; init; }
    public required string RefreshToken { get; init; }
    public required DateTime AccessTokenExpiresAt { get; init; }
    public required DateTime RefreshTokenExpiresAt { get; init; }
}
