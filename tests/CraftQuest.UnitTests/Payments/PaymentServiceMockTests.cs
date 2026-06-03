using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Net.Http;

namespace CraftQuest.UnitTests.Payments;

public class PaymentServiceMockTests
{
    [Fact]
    public async Task CapturePayPalOrder_InMockMode_ActivatesPlan()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();

        var service = CreatePaymentService(db);

        var order = await service.CreatePayPalOrderAsync(
            userId,
            new PayPalCreateOrderRequest { PlanCode = "pro" });

        var capture = await service.CapturePayPalOrderAsync(
            userId,
            new PayPalCaptureOrderRequest { OrderId = order.OrderId });

        Assert.Equal("validated", capture.Status);
        Assert.Equal("pro", capture.PlanCode);

        var activePlan = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .Select(s => s.Plan.Code)
            .FirstAsync();

        Assert.Equal("pro", activePlan);
    }

    [Fact]
    public async Task CreatePayPalOrder_InMockMode_CreatesPendingPurchase()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();

        var service = CreatePaymentService(db);
        var order = await service.CreatePayPalOrderAsync(
            userId,
            new PayPalCreateOrderRequest { PlanCode = "pro" });

        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        Assert.Equal(order.OrderId, purchase.ProviderTransactionId);
        Assert.Equal("pro", purchase.ProductCode);
        Assert.Equal("pending", purchase.Status);
        Assert.Equal("paypal", purchase.ProviderCode);
    }

    [Fact]
    public async Task CapturePayPalOrder_InMockMode_ValidatesPurchaseAndAppearsInHistory()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var billing = new BillingService(db);
        var service = CreatePaymentService(db);

        var order = await service.CreatePayPalOrderAsync(
            userId,
            new PayPalCreateOrderRequest { PlanCode = "pro" });

        await service.CapturePayPalOrderAsync(
            userId,
            new PayPalCaptureOrderRequest { OrderId = order.OrderId });

        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        Assert.Equal("validated", purchase.Status);
        Assert.NotNull(purchase.PurchasedAt);

        var history = await billing.GetMyPurchasesAsync(userId);
        Assert.Single(history);
        Assert.Equal(purchase.PurchaseId, history[0].PurchaseId);
        Assert.Equal("Pro", history[0].ProductDisplayName);
    }

    [Fact]
    public async Task ActivatePayPalSubscription_InMockMode_SetsAutoRenewAndPeriodEnd()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var billing = new BillingService(db);
        var service = CreatePaymentService(db);

        var created = await service.CreatePayPalSubscriptionAsync(
            userId,
            new PayPalCreateSubscriptionRequest { PlanCode = "pro", BillingCycle = "monthly" });

        var activated = await service.ActivatePayPalSubscriptionAsync(
            userId,
            new PayPalActivateSubscriptionRequest { SubscriptionId = created.SubscriptionId });

        Assert.True(activated.AutoRenewEnabled);
        Assert.NotNull(activated.CurrentPeriodEnd);

        var sub = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstAsync();

        Assert.Equal("pro", sub.Plan.Code);
        Assert.True(sub.AutoRenewEnabled);
        Assert.NotNull(sub.EndsAt);

        var cancel = await billing.CancelAutoRenewAsync(userId);
        Assert.False(cancel.AutoRenewEnabled);
        Assert.True(sub.EndsAt <= cancel.AccessUntil);

        var restore = await service.TryRestoreProviderAutoRenewAsync(userId);
        Assert.True(restore.CanUpdateBilling);
        Assert.False(restore.RequiresResubscribe);

        var resume = await billing.ReactivateAutoRenewAsync(userId);
        Assert.True(resume.AutoRenewEnabled);
        Assert.NotNull(resume.NextRenewalAt);

        await db.Entry(sub).ReloadAsync();
        Assert.True(sub.AutoRenewEnabled);
        Assert.False(sub.CancelAtPeriodEnd);
    }

    [Fact]
    public async Task VerifyMobilePurchase_InMockMode_ActivatesSubscriptionWithPeriod()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var service = CreatePaymentService(db);

        var result = await service.VerifyMobilePurchaseAsync(
            userId,
            new VerifyMobilePurchaseRequest
            {
                Platform = "google_play",
                ProductId = "craftquest_pro_monthly",
                PurchaseToken = "gp-token-123",
            });

        Assert.Equal("pro", result.PlanCode);
        Assert.Equal("validated", result.Status);
        Assert.True(result.AutoRenewEnabled);
        Assert.NotNull(result.CurrentPeriodEnd);

        var sub = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstAsync();
        Assert.Equal("pro", sub.Plan.Code);
        Assert.Equal("gp-token-123", sub.ProviderSubscriptionId);
    }

    [Fact]
    public async Task CapturePayPalOrder_WhenAlreadyValidated_IsIdempotent()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var service = CreatePaymentService(db);

        var order = await service.CreatePayPalOrderAsync(
            userId,
            new PayPalCreateOrderRequest { PlanCode = "pro" });

        await service.CapturePayPalOrderAsync(
            userId,
            new PayPalCaptureOrderRequest { OrderId = order.OrderId });
        var second = await service.CapturePayPalOrderAsync(
            userId,
            new PayPalCaptureOrderRequest { OrderId = order.OrderId });

        Assert.Equal("validated", second.Status);
        Assert.Equal(1, await db.Purchases.CountAsync(p => p.UserId == userId));
    }

    private static PaymentService CreatePaymentService(CraftQuestDbContext db)
    {
        var billing = new BillingService(db);
        var paymentOptions = Options.Create(new PaymentOptions
        {
            UseMockPayments = true,
            PlanProducts = new Dictionary<string, PlanProductMapping>
            {
                ["pro"] = new()
                {
                    GooglePlayProductId = "craftquest_pro_monthly",
                    AppStoreProductId = "craftquest_pro_monthly",
                },
                ["teacher"] = new()
                {
                    GooglePlayProductId = "craftquest_teacher_monthly",
                    AppStoreProductId = "craftquest_teacher_monthly",
                },
            },
        });
        var payPal = new PayPalApiClient(new HttpClient(), paymentOptions);
        var google = new GooglePlaySubscriptionVerifier(paymentOptions);
        var apple = new AppleAppStoreSubscriptionVerifier(
            new HttpClientFactoryStub(),
            paymentOptions);
        var mobileVerifier = new MobileStoreSubscriptionVerifier(google, apple);
        var webhooks = new MobileStoreWebhookProcessor(
            db,
            billing,
            new AppleAppStoreJwsVerifier(paymentOptions),
            paymentOptions);
        return new PaymentService(
            db,
            billing,
            payPal,
            mobileVerifier,
            webhooks,
            paymentOptions);
    }

    private sealed class HttpClientFactoryStub : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new();
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task SeedPlansAndUserAsync(CraftQuestDbContext db)
    {
        db.Plans.Add(new Plan
        {
            PlanId = 1,
            Code = "free",
            Name = "Free",
            IsActive = true,
            MonthlyShareCodes = 2,
        });
        db.Plans.Add(new Plan
        {
            PlanId = 2,
            Code = "pro",
            Name = "Pro",
            MonthlyPrice = 4.99m,
            IsActive = true,
            MonthlyAiCredits = 150,
            MonthlyShareCodes = 20,
        });

        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "pay@test.com",
            PasswordHash = [1, 2, 3],
            DisplayName = "Pay Test",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 1,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
    }
}
