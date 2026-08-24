using CraftQuest.Application.Options;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class PaymentStartupValidator(
    IOptions<PaymentOptions> options,
    IHostEnvironment environment,
    ILogger<PaymentStartupValidator> logger) : IHostedService
{
    public Task StartAsync(CancellationToken cancellationToken)
    {
        if (!environment.IsProduction())
        {
            return Task.CompletedTask;
        }

        var payments = options.Value;
        if (payments.UseMockPayments)
        {
            logger.LogCritical(
                "Payments:UseMockPayments is enabled in Production. Real payment verification is disabled.");
        }

        var returnUrl = payments.PayPal.ReturnUrl ?? string.Empty;
        if (returnUrl.Contains("localhost", StringComparison.OrdinalIgnoreCase))
        {
            logger.LogCritical(
                "Payments:PayPal:ReturnUrl points to localhost in Production: {ReturnUrl}",
                returnUrl);
        }

        if (payments.PayPal.ApiBaseUrl.Contains("sandbox", StringComparison.OrdinalIgnoreCase))
        {
            logger.LogCritical(
                "Payments:PayPal:ApiBaseUrl is sandbox in Production: {ApiBaseUrl}",
                payments.PayPal.ApiBaseUrl);
        }

        if (string.IsNullOrWhiteSpace(payments.PayPal.ClientId)
            || string.IsNullOrWhiteSpace(payments.PayPal.ClientSecret))
        {
            logger.LogCritical("Payments:PayPal ClientId or ClientSecret is missing in Production.");
        }

        ValidateMobileStoreCredentials(payments.Mobile);

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    private void ValidateMobileStoreCredentials(MobileStoreOptions mobile)
    {
        var googleJsonPath = mobile.GooglePlayServiceAccountJsonPath ?? string.Empty;
        if (string.IsNullOrWhiteSpace(googleJsonPath)
            || !File.Exists(googleJsonPath))
        {
            logger.LogCritical(
                "Google Play service account JSON is missing or unreadable in Production. Path={Path}",
                string.IsNullOrWhiteSpace(googleJsonPath) ? "(empty)" : googleJsonPath);
        }

        var hasAppleServerApi = !string.IsNullOrWhiteSpace(mobile.AppleIssuerId)
            && !string.IsNullOrWhiteSpace(mobile.AppleKeyId)
            && !string.IsNullOrWhiteSpace(mobile.ApplePrivateKeyPath)
            && File.Exists(mobile.ApplePrivateKeyPath);

        var hasAppleSharedSecret = !string.IsNullOrWhiteSpace(mobile.AppleSharedSecret);

        if (!hasAppleServerApi && !hasAppleSharedSecret)
        {
            logger.LogCritical(
                "App Store credentials are missing in Production. Configure Apple Issuer/Key/.p8 or AppleSharedSecret.");
        }

        if (string.Equals(mobile.AppleEnvironment, "Sandbox", StringComparison.OrdinalIgnoreCase))
        {
            logger.LogCritical(
                "Payments:Mobile:AppleEnvironment is Sandbox in Production. App Store purchases may fail verification.");
        }
    }
}
