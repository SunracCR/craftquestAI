using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
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
        var billing = BillingTestHelpers.CreateService(db);
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
        var billing = BillingTestHelpers.CreateService(db);
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
    public async Task ActivatePayPalSubscription_WhenPurchaseValidatedButPlanStillFree_RepairsActivation()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var service = CreatePaymentService(db);

        var created = await service.CreatePayPalSubscriptionAsync(
            userId,
            new PayPalCreateSubscriptionRequest { PlanCode = "pro", BillingCycle = "monthly" });

        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        purchase.Status = "validated";
        purchase.PurchasedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        var activated = await service.ActivatePayPalSubscriptionAsync(
            userId,
            new PayPalActivateSubscriptionRequest { SubscriptionId = created.SubscriptionId });

        Assert.Equal("pro", activated.PlanCode);

        var activePlan = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .Select(s => s.Plan.Code)
            .FirstAsync();

        Assert.Equal("pro", activePlan);
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
    public async Task VerifyMobilePurchase_RenewalWithNewTransactionId_DoesNotDuplicatePurchaseRecord()
    {
        // Regresion: cuando el usuario ya tiene una suscripcion activa con el
        // mismo ProviderSubscriptionId (renovacion de sandbox/App Store) y
        // llega un ProviderTransactionId que aun no existe en Purchases,
        // VerifyMobilePurchaseAsync y BillingService.RenewSubscriptionPeriodAsync
        // no deben crear dos filas de Purchase para el mismo transactionId
        // (violaria el indice unico UX_Purchases_ProviderTransaction en SQL real).
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();

        var freeSub = await db.UserSubscriptions.SingleAsync(s => s.UserId == userId);
        freeSub.Status = "cancelled";
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 2,
            Status = "active",
            StartedAt = DateTime.UtcNow.AddDays(-30),
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            ProviderCode = "app_store",
            ProviderSubscriptionId = "orig-transaction-1",
            BillingCycle = "monthly",
            AutoRenewEnabled = true,
        });
        await db.SaveChangesAsync();

        var service = CreatePaymentService(db);

        var result = await service.VerifyMobilePurchaseAsync(
            userId,
            new VerifyMobilePurchaseRequest
            {
                Platform = "app_store",
                ProductId = "craftquest_pro_monthly",
                PurchaseToken = "orig-transaction-1",
            });

        Assert.Equal("pro", result.PlanCode);
        Assert.Equal("validated", result.Status);

        var purchaseCount = await db.Purchases.CountAsync(
            p => p.ProviderCode == "app_store" && p.ProviderTransactionId == "orig-transaction-1");
        Assert.Equal(1, purchaseCount);

        var sub = await db.UserSubscriptions
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstAsync();
        Assert.Equal("app_store", sub.ProviderCode);
        Assert.True(sub.EndsAt > DateTime.UtcNow);
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


    [Fact]
    public async Task ProcessPayPalWebhook_SubscriptionActivated_ValidatesPendingPurchase()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var service = CreatePaymentService(db);

        var subscription = await service.CreatePayPalSubscriptionAsync(
            userId,
            new PayPalCreateSubscriptionRequest { PlanCode = "pro" });

        var body = $$"""
            {
              "id": "WH-TEST-ACTIVATED",
              "event_type": "BILLING.SUBSCRIPTION.ACTIVATED",
              "resource": {
                "id": "{{subscription.SubscriptionId}}"
              }
            }
            """;

        await service.ProcessPayPalWebhookAsync("ignored", "UNKNOWN", body);

        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        Assert.Equal("validated", purchase.Status);

        var activePlan = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .Select(s => s.Plan.Code)
            .FirstAsync();
        Assert.Equal("pro", activePlan);
    }

    [Fact]
    public async Task ProcessPayPalWebhook_OrderCompleted_ValidatesPendingOneTimeOrder()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();
        var service = CreatePaymentService(db);

        var order = await service.CreatePayPalOrderAsync(
            userId,
            new PayPalCreateOrderRequest { PlanCode = "pro" });

        var body = $$"""
            {
              "id": "WH-TEST-ORDER",
              "event_type": "CHECKOUT.ORDER.COMPLETED",
              "resource": {
                "id": "{{order.OrderId}}"
              }
            }
            """;

        await service.ProcessPayPalWebhookAsync("ignored", "UNKNOWN", body);

        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        Assert.Equal("validated", purchase.Status);
    }

    [Fact]
    public async Task ReconcilePendingPurchases_ActivatesOldPayPalSubscription_MockMode()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();

        db.Purchases.Add(new Purchase
        {
            PurchaseId = Guid.NewGuid(),
            UserId = userId,
            ProductCode = "pro",
            ProductType = "subscription",
            ProviderCode = "paypal",
            ProviderTransactionId = "I-SUB-OLD-PENDING",
            Amount = 9.99m,
            CurrencyCode = "USD",
            Status = "pending",
            BillingCycle = "monthly",
            CreatedAt = DateTime.UtcNow.AddHours(-7),
        });
        await db.SaveChangesAsync();

        var service = CreatePaymentService(db);
        var reconciled = await service.ReconcilePendingPurchasesAsync();

        Assert.Equal(1, reconciled);
        var purchase = await db.Purchases.SingleAsync(p => p.UserId == userId);
        Assert.Equal("validated", purchase.Status);
    }

    private static PaymentService CreatePaymentService(CraftQuestDbContext db)
    {
        var billing = BillingTestHelpers.CreateService(db);
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
        var payPal = new PayPalApiClient(
            new HttpClient(),
            paymentOptions,
            NullLogger<PayPalApiClient>.Instance);
        var google = new GooglePlaySubscriptionVerifier(paymentOptions);
        var googleProducts = new GooglePlayProductVerifier(
            paymentOptions,
            NullLogger<GooglePlayProductVerifier>.Instance);
        var apple = new AppleAppStoreSubscriptionVerifier(
            new HttpClientFactoryStub(),
            paymentOptions);
        var mobileVerifier = new MobileStoreSubscriptionVerifier(google, apple);
        var mobileProductVerifier = new MobileStoreProductVerifier(googleProducts, apple);
        var webhooks = new MobileStoreWebhookProcessor(
            db,
            billing,
            google,
            new CraftQuest.UnitTests.Notifications.NoOpNotificationService(),
            new AppleAppStoreJwsVerifier(paymentOptions),
            paymentOptions,
            NullLogger<MobileStoreWebhookProcessor>.Instance);
        return new PaymentService(
            db,
            billing,
            payPal,
            mobileVerifier,
            mobileProductVerifier,
            webhooks,
            PaymentServiceMockTests.CreateStubPrepPlusPaymentService(),
            paymentOptions,
            NullLogger<PaymentService>.Instance);
    }

    private sealed class HttpClientFactoryStub : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new();
    }

    internal static StubPrepPlusPaymentService CreateStubPrepPlusPaymentService() =>
        new();

    internal sealed class StubPrepPlusPaymentService : CraftQuest.Application.Contracts.IPrepPlusPaymentService
    {
        public Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
            Guid userId,
            Guid catalogItemId,
            Guid offerId,
            string? referralCode = null,
            CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Prep+ PayPal create was not expected in this test.");

        public Task<CraftQuest.Application.Models.PrepPlus.PrepCheckoutResultDto> CapturePayPalOrderAsync(
            Guid userId,
            PayPalCaptureOrderRequest request,
            CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Prep+ PayPal capture was not expected in this test.");

        public Task<CraftQuest.Application.Models.PrepPlus.PrepCheckoutResultDto> VerifyMobilePurchaseAsync(
            Guid userId,
            CraftQuest.Application.Models.PrepPlus.PrepMobilePurchaseRequest request,
            CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Prep+ mobile verify was not expected in this test.");
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
