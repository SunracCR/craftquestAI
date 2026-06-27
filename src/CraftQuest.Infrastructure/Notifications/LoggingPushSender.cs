using CraftQuest.Application.Contracts;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Notifications;

public sealed class LoggingPushSender(ILogger<LoggingPushSender> logger) : IPushSender
{
    public Task SendAsync(
        Guid userId,
        string title,
        string body,
        IReadOnlyDictionary<string, string>? data,
        CancellationToken cancellationToken = default)
    {
        logger.LogInformation(
            "Push (disabled) user={UserId} title={Title} body={Body}",
            userId,
            title,
            body);
        return Task.CompletedTask;
    }

    public Task RemoveInvalidTokenAsync(string token, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
