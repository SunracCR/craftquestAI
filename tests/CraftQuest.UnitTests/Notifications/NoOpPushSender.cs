using CraftQuest.Application.Contracts;

namespace CraftQuest.UnitTests.Notifications;

internal sealed class NoOpPushSender : IPushSender
{
    public Task SendAsync(
        Guid userId,
        string title,
        string body,
        IReadOnlyDictionary<string, string>? data,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task RemoveInvalidTokenAsync(string token, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
