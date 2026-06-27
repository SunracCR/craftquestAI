using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Notifications;

public static class NotificationPublisher
{
    public static async Task TryNotifyAsync(
        Func<Task> action,
        ILogger logger,
        string context)
    {
        try
        {
            await action();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Notification failed: {Context}", context);
        }
    }

    /// <summary>
    /// Runs notification work on a background thread with its own DI scope so HTTP
    /// handlers are not blocked by push, email, or extra DB round-trips.
    /// </summary>
    public static void TryNotifyInBackground(
        IServiceScopeFactory scopeFactory,
        Func<IServiceProvider, CancellationToken, Task> action,
        ILogger logger,
        string context)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                await action(scope.ServiceProvider, CancellationToken.None);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Notification failed: {Context}", context);
            }
        });
    }
}
