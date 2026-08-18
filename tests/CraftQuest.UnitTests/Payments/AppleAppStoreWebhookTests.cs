using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
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

public class AppleAppStoreWebhookTests
{
    [Fact]
    public async Task ProcessAppleNotificationAsync_TestNotification_DoesNotRecordEvent()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db, out _);

        var body = BuildWebhookBody(new
        {
            notificationType = "TEST",
            notificationUUID = "test-uuid-1",
        });

        var exception = await Record.ExceptionAsync(
            () => processor.ProcessAppleNotificationAsync(body, CancellationToken.None));

        Assert.Null(exception);
        Assert.Empty(await db.ProviderWebhookEvents.ToListAsync());
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_InvalidPayload_DoesNotThrow()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db, out _);

        var exception = await Record.ExceptionAsync(
            () => processor.ProcessAppleNotificationAsync("{}", CancellationToken.None));

        Assert.Null(exception);
        Assert.Empty(await db.ProviderWebhookEvents.ToListAsync());
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_Revoke_RevokesSubscriptionImmediately()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedAppStoreSubscriptionAsync(db, userId, "revoke-otx");
        var processor = CreateProcessor(db, out _);

        var body = BuildWebhookBody(
            new
            {
                notificationType = "REVOKE",
                notificationUUID = "revoke-uuid",
            },
            originalTransactionId: "revoke-otx");

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var active = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .SingleAsync();

        Assert.Equal("free", active.Plan.Code);
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_Refund_RevokesSubscriptionImmediately()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedAppStoreSubscriptionAsync(db, userId, "refund-otx");
        var processor = CreateProcessor(db, out _);

        var body = BuildWebhookBody(
            new
            {
                notificationType = "REFUND",
                notificationUUID = "refund-uuid",
            },
            originalTransactionId: "refund-otx");

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var active = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .SingleAsync();

        Assert.Equal("free", active.Plan.Code);
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_DidRenew_ExtendsSubscriptionPeriod()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedAppStoreSubscriptionAsync(db, userId, "renew-otx");
        var originalEndsAt = await db.UserSubscriptions
            .AsNoTracking()
            .Where(s => s.UserSubscriptionId == subscriptionId)
            .Select(s => s.EndsAt)
            .SingleAsync();
        var processor = CreateProcessor(db, out _);
        var newExpiry = DateTimeOffset.UtcNow.AddDays(30).ToUnixTimeMilliseconds();

        var body = BuildWebhookBody(
            new
            {
                notificationType = "DID_RENEW",
                notificationUUID = "renew-uuid",
            },
            originalTransactionId: "renew-otx",
            expiresDate: newExpiry,
            autoRenewStatus: 1);

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.EndsAt > originalEndsAt);
        Assert.True(subscription.AutoRenewEnabled);
        Assert.False(subscription.PaymentIssuePending);
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_GracePeriod_SetsPaymentIssuePendingAndNotifies()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedAppStoreSubscriptionAsync(db, userId, "grace-otx");
        var processor = CreateProcessor(db, out var notifications);

        var body = BuildWebhookBody(
            new
            {
                notificationType = "DID_FAIL_TO_RENEW",
                subtype = "GRACE_PERIOD",
                notificationUUID = "grace-uuid",
            },
            originalTransactionId: "grace-otx",
            autoRenewStatus: 1);

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.PaymentIssuePending);
        Assert.Contains(
            notifications.Sent,
            n => n.UserId == userId && n.Type == NotificationTypes.PaymentIssuePending);
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_DuplicateNotificationUuid_IsIgnored()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedAppStoreSubscriptionAsync(db, userId, "dup-otx");
        var processor = CreateProcessor(db, out _);

        var body = BuildWebhookBody(
            new
            {
                notificationType = "EXPIRED",
                notificationUUID = "dup-uuid",
            },
            originalTransactionId: "dup-otx");

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);
        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var events = await db.ProviderWebhookEvents.ToListAsync();
        Assert.Single(events);
        Assert.Equal("EXPIRED", events[0].EventType);
    }

    [Fact]
    public async Task ProcessAppleNotificationAsync_Expired_RecordsEventTypeWithSubtype()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscriptionId = await SeedAppStoreSubscriptionAsync(db, userId, "expired-otx");
        var processor = CreateProcessor(db, out _);

        var body = BuildWebhookBody(
            new
            {
                notificationType = "EXPIRED",
                subtype = "VOLUNTARY",
                notificationUUID = "expired-uuid",
            },
            originalTransactionId: "expired-otx",
            autoRenewStatus: 0);

        await processor.ProcessAppleNotificationAsync(body, CancellationToken.None);

        var events = await db.ProviderWebhookEvents.ToListAsync();
        Assert.Single(events);
        Assert.Equal("EXPIRED:VOLUNTARY", events[0].EventType);

        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        Assert.NotNull(subscription);
        Assert.True(subscription!.CancelAtPeriodEnd);
        Assert.False(subscription.AutoRenewEnabled);
        Assert.Equal(SubscriptionStatuses.Active, subscription.Status);
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

    private static async Task<Guid> SeedAppStoreSubscriptionAsync(
        CraftQuestDbContext db,
        Guid userId,
        string originalTransactionId)
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
            ProviderCode = "app_store",
            ProviderSubscriptionId = originalTransactionId,
            BillingCycle = BillingCycles.Monthly,
            AutoRenewEnabled = true,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
        return subscriptionId;
    }

    private static string BuildWebhookBody(
        object notificationPayload,
        string originalTransactionId = "otx-default",
        long? expiresDate = null,
        int? autoRenewStatus = null)
    {
        var txPayload = new JsonObject
        {
            ["originalTransactionId"] = originalTransactionId,
            ["transactionId"] = $"{originalTransactionId}-tx",
        };
        if (expiresDate.HasValue)
        {
            txPayload["expiresDate"] = expiresDate.Value;
        }

        var data = new JsonObject
        {
            ["signedTransactionInfo"] = BuildUnsignedJws(txPayload),
        };
        if (autoRenewStatus.HasValue)
        {
            data["signedRenewalInfo"] = BuildUnsignedJws(new JsonObject
            {
                ["autoRenewStatus"] = autoRenewStatus.Value,
            });
        }

        var root = JsonSerializer.SerializeToNode(notificationPayload)!.AsObject();
        root["data"] = data;

        var signedPayload = BuildUnsignedJws(root);
        return JsonSerializer.Serialize(new { signedPayload });
    }

    private static string BuildUnsignedJws(JsonNode payload)
    {
        var header = Base64UrlEncode("{}");
        var payloadSegment = Base64UrlEncode(payload.ToJsonString());
        var signature = Base64UrlEncode("test-signature");
        return $"{header}.{payloadSegment}.{signature}";
    }

    private static string Base64UrlEncode(string value) =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
}
