using CraftQuest.Application.Models.Notifications;

namespace CraftQuest.Application.Contracts;

public interface INotificationService
{
    Task NotifyAsync(
        Guid userId,
        string type,
        NotificationPayload payload,
        string? dedupKey = null,
        CancellationToken cancellationToken = default);

    Task NotifyManyAsync(
        IReadOnlyList<Guid> userIds,
        string type,
        NotificationPayload payload,
        Func<Guid, string?>? dedupKeyFactory = null,
        CancellationToken cancellationToken = default);

    Task EnqueueFanOutAsync(
        string eventType,
        string payloadJson,
        CancellationToken cancellationToken = default);

    Task<NotificationListResultDto> ListAsync(
        Guid userId,
        string? cursor,
        int limit,
        bool unreadOnly,
        CancellationToken cancellationToken = default);

    Task<int> CountUnreadAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task MarkReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken = default);

    Task MarkAllReadAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task RegisterDeviceTokenAsync(
        Guid userId,
        RegisterDeviceTokenRequest request,
        CancellationToken cancellationToken = default);

    Task RemoveDeviceTokenAsync(
        Guid userId,
        string token,
        CancellationToken cancellationToken = default);

    Task<NotificationPreferencesDto> GetPreferencesAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task UpdatePreferencesAsync(
        Guid userId,
        UpdateNotificationPreferencesRequest request,
        CancellationToken cancellationToken = default);
}

public interface IPushSender
{
    Task SendAsync(
        Guid userId,
        string title,
        string body,
        IReadOnlyDictionary<string, string>? data,
        CancellationToken cancellationToken = default);

    Task RemoveInvalidTokenAsync(
        string token,
        CancellationToken cancellationToken = default);
}
