using CraftQuest.Application.Models.Auth;

namespace CraftQuest.Application.Contracts;

public interface IAuthService
{
    OAuthPublicConfigDto GetOAuthPublicConfig();

    Task<AuthResponseDto> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponseDto> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponseDto> LoginWithGoogleAsync(
        ExternalLoginRequest request,
        CancellationToken cancellationToken = default);
    Task<AuthResponseDto> LoginWithAppleAsync(
        ExternalLoginRequest request,
        CancellationToken cancellationToken = default);
    Task<AuthTokensDto> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
    Task<UserProfileDto> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserProfileDto> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken = default);
    Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>Always completes without revealing whether the email exists.</summary>
    Task RequestPasswordResetAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default);

    Task ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default);
}
