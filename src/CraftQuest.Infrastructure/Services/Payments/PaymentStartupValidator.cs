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

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
