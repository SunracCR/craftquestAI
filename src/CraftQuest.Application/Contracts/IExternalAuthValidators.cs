namespace CraftQuest.Application.Contracts;

public sealed record ExternalAuthUserInfo(
    string Subject,
    string? Email,
    string? DisplayName,
    bool EmailVerified);

public interface IGoogleIdTokenValidator
{
    Task<ExternalAuthUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default);
}

public interface IAppleIdTokenValidator
{
    Task<ExternalAuthUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default);
}
