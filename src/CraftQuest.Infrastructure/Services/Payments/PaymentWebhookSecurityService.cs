using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class PaymentWebhookSecurityService(
    IOptions<PaymentOptions> options,
    PayPalApiClient payPalApiClient,
    GooglePubSubJwtValidator googlePubSubJwtValidator,
    AppleAppStoreJwsVerifier appleJwsVerifier)
{
    public bool IsVerificationEnabled =>
        !options.Value.UseMockPayments && options.Value.Webhooks.RequireVerification;

    public async Task VerifyPayPalAsync(
        IReadOnlyDictionary<string, string> headers,
        string body,
        CancellationToken cancellationToken = default)
    {
        if (!IsVerificationEnabled || !options.Value.PayPal.VerifyWebhooks)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(options.Value.PayPal.WebhookId))
        {
            throw new AppException(
                "Payments:PayPal:WebhookId is required when webhook verification is enabled.",
                503);
        }

        var verified = await payPalApiClient.VerifyWebhookSignatureAsync(headers, body, cancellationToken);
        if (!verified)
        {
            throw new AppException("PayPal webhook signature verification failed.", 401);
        }
    }

    public Task VerifyGooglePubSubAsync(
        string? authorizationHeader,
        CancellationToken cancellationToken = default) =>
        googlePubSubJwtValidator.ValidateAuthorizationHeaderAsync(authorizationHeader, cancellationToken);

    public void VerifyAppleSignedPayload(string rawBody)
    {
        if (!IsVerificationEnabled)
        {
            return;
        }

        using var doc = JsonDocument.Parse(rawBody);
        if (!doc.RootElement.TryGetProperty("signedPayload", out var signedPayloadEl))
        {
            throw new AppException("Invalid Apple notification payload.", 400);
        }

        appleJwsVerifier.VerifySignedPayload(signedPayloadEl.GetString()!);
    }
}
