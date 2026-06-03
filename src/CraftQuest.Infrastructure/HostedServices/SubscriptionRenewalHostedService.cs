using CraftQuest.Application.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.HostedServices;

/// <summary>
/// Expira suscripciones cuyo periodo terminó sin renovación (respaldo si falla un webhook).
/// </summary>
public sealed class SubscriptionRenewalHostedService(
    IServiceScopeFactory scopeFactory,
    ILogger<SubscriptionRenewalHostedService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var billing = scope.ServiceProvider.GetRequiredService<IBillingService>();
                var expired = await billing.ProcessExpiredSubscriptionsAsync(stoppingToken);
                if (expired > 0)
                {
                    logger.LogInformation(
                        "Subscription renewal job expired {Count} user subscription(s).",
                        expired);
                }
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(ex, "Subscription renewal job failed.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }
}
