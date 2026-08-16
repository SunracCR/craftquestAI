using System.Text;
using System.Text.Json;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Payments;
using CraftQuest.UnitTests.Billing;
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
        var processor = CreateProcessor(db);

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
        var processor = CreateProcessor(db);

        var exception = await Record.ExceptionAsync(
            () => processor.ProcessGooglePlayPubSubAsync("{}", CancellationToken.None));

        Assert.Null(exception);
    }

    [Fact]
    public async Task ProcessGooglePlayPubSubAsync_SubscriptionWithoutLocalRow_RecordsEventOnly()
    {
        await using var db = CreateDb();
        var processor = CreateProcessor(db);

        var inner = JsonSerializer.Serialize(new
        {
            version = "1.0",
            packageName = "com.craftquestai.craftquestai_app",
            eventTimeMillis = "1234567890123",
            subscriptionNotification = new
            {
                version = "1.0",
                notificationType = 2,
                purchaseToken = "test-purchase-token",
                subscriptionId = "craftquest_pro_monthly",
            },
        });
        var envelope = BuildPubSubEnvelope(inner);

        await processor.ProcessGooglePlayPubSubAsync(envelope, CancellationToken.None);

        var events = await db.ProviderWebhookEvents.ToListAsync();
        Assert.Single(events);
        Assert.Equal("google_play", events[0].ProviderCode);
        Assert.Equal("type-2", events[0].EventType);
    }

    private static MobileStoreWebhookProcessor CreateProcessor(CraftQuestDbContext db)
    {
        var paymentOptions = Options.Create(new PaymentOptions { UseMockPayments = true });
        return new MobileStoreWebhookProcessor(
            db,
            BillingTestHelpers.CreateService(db),
            new AppleAppStoreJwsVerifier(paymentOptions),
            paymentOptions,
            NullLogger<MobileStoreWebhookProcessor>.Instance);
    }

    private static CraftQuestDbContext CreateDb() =>
        new(new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

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
