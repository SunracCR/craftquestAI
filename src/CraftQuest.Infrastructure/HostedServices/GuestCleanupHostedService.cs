using CraftQuest.Application.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.HostedServices;

public class GuestCleanupHostedService(
    IServiceScopeFactory scopeFactory,
    ILogger<GuestCleanupHostedService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(30);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Guest cleanup service started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(Interval, stoppingToken);

                using var scope = scopeFactory.CreateScope();
                var guestService = scope.ServiceProvider.GetRequiredService<IGuestService>();
                await guestService.PurgeExpiredVisitsAsync(stoppingToken);

                logger.LogDebug("Guest visit purge completed.");
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error during guest visit purge.");
            }
        }
    }
}
