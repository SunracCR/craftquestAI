using CraftQuest.Application.Contracts;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;

namespace CraftQuest.UnitTests.Billing;

internal static class BillingTestHelpers
{
    public static BillingService CreateService(CraftQuestDbContext db) =>
        new(
            db,
            new MemoryCache(new MemoryCacheOptions()),
            new NoOpNotificationService(),
            NullLogger<BillingService>.Instance);

    private sealed class NoOpNotificationService : INotificationService
    {
        public Task NotifyAsync(
            Guid userId,
            string type,
            Application.Models.Notifications.NotificationPayload payload,
            string? dedupKey = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task NotifyManyAsync(
            IReadOnlyList<Guid> userIds,
            string type,
            Application.Models.Notifications.NotificationPayload payload,
            Func<Guid, string?>? dedupKeyFactory = null,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task EnqueueFanOutAsync(
            string eventType,
            string payloadJson,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<Application.Models.Notifications.NotificationListResultDto> ListAsync(
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
            Application.Models.Notifications.RegisterDeviceTokenRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task RemoveDeviceTokenAsync(
            Guid userId,
            string token,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task<Application.Models.Notifications.NotificationPreferencesDto> GetPreferencesAsync(
            Guid userId,
            CancellationToken cancellationToken = default) =>
            throw new NotImplementedException();

        public Task UpdatePreferencesAsync(
            Guid userId,
            Application.Models.Notifications.UpdateNotificationPreferencesRequest request,
            CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
