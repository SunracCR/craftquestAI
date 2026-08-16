using System.Text;
using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Payments;
using CraftQuest.UnitTests.Billing;
using CraftQuest.UnitTests.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Payments;

public class GooglePlayPubSubWebhookTests
{
    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_TestNotification_DoesNotThrow()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db, out _);

        var inner = JsonSerializer.Serialize(new
        {
            version = "1.0",
            packageName = "com.craftquestai.craftquestai_app",
            eventTimeMillis = "1234567890123",
            testNotification = new { version = "1.0" },
        });
        var envelope = BuildPubSubEnvelope(inner);

        var exception = await Record.ExceptionAsync(
            () => processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None));

        Assert.Null(exception);
        Assert.Empty(await db.ProviderWebhookEvents.ToListAsync());
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_InvalidEnvelope_DoesNotThrow()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db, out _);

        var exception = await Record.ExceptionAsync(
            () => processor.ProcessGooglePlayPubSubAsync("{}", CancellationToken.None));

        Assert.Null(exception);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_SubscriptionWithoutLocalRow_RecordsEventOnly()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db, out _);

        var inner = BuildSubscriptionNotificationInner(2, "missing-token");
        var envelope = BuildPubSubEnvelope(inner);

        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var events = await db.ProviderWebhookEvents.ToListAsync();
        Assert.Single(events);
        Assert.Equal("google_play", events[0].ProviderCode);
        Assert.Equal("type-2", events[0].EventType);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_Type12_RevokesSubscriptionImmediately()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedGooglePlaySubscriptionAsync(db, userId, "revoke-token");
        var processor = CreateProcessor(db, out _);

        var envelope = BuildPubSubEnvelope(BuildSubscriptionNotificationInner(12, "revoke-token"));
        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var active = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .SingleAsync();

        Assert.Equal("free", active.Plan.Code);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_Type6_SetsPaymentIssuePendingAndNotifies()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedGooglePlaySubscriptionAsync(db, userId, "grace-token");
        var processor = CreateProcessor(db, out var notifications);

        var envelope = BuildPubSubEnvelope(BuildSubscriptionNotificationInner(6, "grace-token"));
        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.PaymentIssuePending);
        Assert.Contains(
            notifications.Sent,
            n => n.UserId == userId && n.Type == NotificationTypes.PaymentIssuePending);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_Type3_MarksCancelAtPeriodEndOnly()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedGooglePlaySubscriptionAsync(db, userId, "cancel-token");
        var processor = CreateProcessor(db, out _);

        var envelope = BuildPubSubEnvelope(BuildSubscriptionNotificationInner(3, "cancel-token"));
        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.CancelAtPeriodEnd);
        Assert.False(subscription.AutoRenewEnabled);
        Assert.Equal(SubscriptionStatuses.Active, subscription.Status);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_Type2_RenewsUsingLocalFallbackWhenGoogleUnavailable()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedGooglePlaySubscriptionAsync(db, userId, "renew-token");
        var originalEndsAt = await db.UserSubscriptions
            .AsNoTracking()
            .Where(s => s.UserSubscriptionId == subscriptionId)
            .Select(s => s.EndsAt)
            .SingleAsync();
        var processor = CreateProcessor(db, out _);

        var envelope = BuildPubSubEnvelope(BuildSubscriptionNotificationInner(2, "renew-token"));
        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.EndsAt > originalEndsAt);
        Assert.False(subscription.PaymentIssuePending);
    }

    private static MobileStoreWebhookProcessor CreateProcessor(
        CraftQuestDbContext db,
        out NoOpNotificationService notifications)
    {
        var paymentOptions = Options.Create(new PaymentOptions { UseMockPayments = true });
        notifications = new NoOpNotificationService();
        return new MobileStoreWebhookProcessor(
            db,
            BillingTestHelpers.CreateService(db),
            new GooglePlaySubscriptionVerifier(paymentOptions),
            notifications,
            new AppleAppStoreJwsVerifier(paymentOptions),
            paymentOptions,
            NullLogger<MobileStoreWebhookProcessor>.Instance);
    }

    private static CraftQuestDbContext CreateDb() =>
        new(new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private static async Task<Guid> SeedGooglePlaySubscriptionAsync(
        CraftQuestDbContext db,
        Guid userId,
        string purchaseToken)
    {
        db.Plans.AddRange(
            new Plan
            {
                PlanId = 1,
                Code = "free",
                Name = "Free",
                IsActive = true,
                MonthlyAiCredits = 20,
            },
            new Plan
            {
                PlanId = 2,
                Code = "pro",
                Name = "Pro",
                IsActive = true,
                MonthlyPrice = 4.99m,
                MonthlyAiCredits = 150,
            });

        db.Users.Add(new User
        {
            UserId = userId,
            Email = $"{userId:N}@test.com",
            PasswordHash = [1],
            DisplayName = "Test",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        var subscriptionId = Guid.NewGuid();
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = subscriptionId,
            UserId = userId,
            PlanId = 2,
            Status = SubscriptionStatuses.Active,
            StartedAt = DateTime.UtcNow.AddDays(-10),
            EndsAt = DateTime.UtcNow.AddDays(5),
            ProviderCode = "google_play",
            ProviderSubscriptionId = purchaseToken,
            BillingCycle = BillingCycles.Monthly,
            AutoRenewEnabled = true,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
        return subscriptionId;
    }

    private static string BuildSubscriptionNotificationInner(int notificationType, string purchaseToken) =>
        JsonSerializer.Serialize(new
        {
            version = "1.0",
            packageName = "com.craftquestai.craftquestai_app",
            eventTimeMillis = "1234567890123",
            subscriptionNotification = new
            {
                version = "1.0",
                notificationType,
                purchaseToken,
                subscriptionId = "craftquest_pro_monthly",
            },
        });

    private static string BuildPubSubEnvelope(string innerJson)
    {
        var data = Convert.ToBase64String(Encoding.UTF8.GetBytes(innerJson));
        return JsonSerializer.Serialize(new
        {
            message = new
            {
                data,
                messageId = "msg-1",
                publishTime = "2026-03-14T00:00:00.000Z",
            },
            subscription = "projects/craftquestai/subscriptions/push-to-backend-playstore",
        });
    }
}
