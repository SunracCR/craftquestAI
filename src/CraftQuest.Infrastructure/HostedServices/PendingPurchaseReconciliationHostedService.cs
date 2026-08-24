using CraftQuest.Application.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.HostedServices;

/// <summary>
/// Reconcilia compras en estado pending que llevan demasiado tiempo sin confirmarse.
/// </summary>
public sealed class PendingPurchaseReconciliationHostedService(
    IServiceScopeFactory scopeFactory,
    ILogger<PendingPurchaseReconciliationHostedService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(2);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var paymentService = scope.ServiceProvider.GetRequiredService<IPaymentService>();
                var reconciled = await paymentService.ReconcilePendingPurchasesAsync(stoppingToken);
                if (reconciled > 0)
                {
                    logger.LogInformation(
                        "Pending purchase reconciliation fulfilled {Count} purchase(s).",
                        reconciled);
                }
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(ex, "Pending purchase reconciliation job failed.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }
}
