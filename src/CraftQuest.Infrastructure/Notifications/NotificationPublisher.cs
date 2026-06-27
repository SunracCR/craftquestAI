using CraftQuest.Application.Contracts;
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
}
