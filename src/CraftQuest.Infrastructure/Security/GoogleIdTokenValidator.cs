using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Security;

public sealed class GoogleIdTokenValidator(IOptions<ExternalAuthOptions> options) : IGoogleIdTokenValidator
{
    public async Task<ExternalAuthUserInfo> ValidateAsync(
        string idToken,
        CancellationToken cancellationToken = default)
    {
        var audiences = GetAudiences();
        if (audiences.Count == 0)
        {
            throw new AuthException(
                "Google sign-in is not configured.",
                503,
                "GOOGLE_AUTH_NOT_CONFIGURED");
        }

        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = audiences,
            };

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);
            return new ExternalAuthUserInfo(
                payload.Subject,
                payload.Email,
                payload.Name,
                payload.EmailVerified);
        }
        catch (InvalidJwtException ex)
        {
            throw new AuthException($"Invalid Google token: {ex.Message}", 401, "INVALID_GOOGLE_TOKEN");
        }
    }

    private IReadOnlyList<string> GetAudiences()
    {
        var google = options.Value.Google;
        var list = new List<string>();
        if (!string.IsNullOrWhiteSpace(google.WebClientId))
        {
            list.Add(google.WebClientId.Trim());
        }

        list.AddRange(google.AdditionalClientIds.Where(id => !string.IsNullOrWhiteSpace(id)).Select(id => id.Trim()));
        return list.Distinct(StringComparer.Ordinal).ToList();
    }
}
