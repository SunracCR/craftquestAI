using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

/// <summary>
/// Valida el JWT Bearer que Google Pub/Sub envía en push subscriptions.
/// </summary>
public sealed class GooglePubSubJwtValidator(IOptions<PaymentOptions> options)
{
    public async Task ValidateAuthorizationHeaderAsync(
        string? authorizationHeader,
        CancellationToken cancellationToken = default)
    {
        if (!IsVerificationEnabled())
        {
            return;
        }

        var audience = options.Value.Webhooks.GooglePubSubAudience?.Trim();
        if (string.IsNullOrWhiteSpace(audience))
        {
            throw new AppException(
                "Payments:Webhooks:GooglePubSubAudience is required when webhook verification is enabled.",
                503);
        }

        var token = ExtractBearerToken(authorizationHeader);
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new AppException("Missing Google Pub/Sub authorization token.", 401);
        }

        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = [audience],
            };

            await GoogleJsonWebSignature.ValidateAsync(token, settings);
        }
        catch (InvalidJwtException ex)
        {
            throw new AppException($"Google Pub/Sub JWT validation failed: {ex.Message}", 401);
        }
    }

    private bool IsVerificationEnabled() =>
        !options.Value.UseMockPayments && options.Value.Webhooks.RequireVerification;

    private static string? ExtractBearerToken(string? authorizationHeader)
    {
        if (string.IsNullOrWhiteSpace(authorizationHeader))
        {
            return null;
        }

        const string prefix = "Bearer ";
        if (!authorizationHeader.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return authorizationHeader[prefix.Length..].Trim();
    }
}
