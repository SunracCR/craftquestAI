using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Notifications;

namespace CraftQuest.UnitTests.Notifications;

internal sealed class NoOpNotificationService : INotificationService
{
    public List<(Guid UserId, string Type)> Sent { get; } = [];

    public Task NotifyAsync(
        Guid userId,
        string type,
        NotificationPayload payload,
        string? dedupKey = null,
        CancellationToken cancellationToken = default)
    {
        Sent.Add((userId, type));
        return Task.CompletedTask;
    }

    public Task NotifyManyAsync(
        IReadOnlyList<Guid> userIds,
        string type,
        NotificationPayload payload,
        Func<Guid, string?>? dedupKeyFactory = null,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task EnqueueFanOutAsync(
        string eventType,
        string payloadJson,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task<NotificationListResultDto> ListAsync(
        Guid userId,
        string? cursor,
        int limit,
        bool unreadOnly,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task<int> CountUnreadAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.FromResult(0);

    public Task MarkReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task MarkAllReadAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task RegisterDeviceTokenAsync(
        Guid userId,
        RegisterDeviceTokenRequest request,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task RemoveDeviceTokenAsync(
        Guid userId,
        string token,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public Task<NotificationPreferencesDto> GetPreferencesAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        throw new NotImplementedException();

    public Task UpdatePreferencesAsync(
        Guid userId,
        UpdateNotificationPreferencesRequest request,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
