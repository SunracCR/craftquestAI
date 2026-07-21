using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Billing;

public class AiCreditPackPaymentTests
{
    [Fact]
    public async Task GetAiCreditPacks_Throws_ForFreePlanUser()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithPlanAsync(db, userId, "free", monthlyAiCredits: 20);

        var service = CreatePaymentService(db);

        await Assert.ThrowsAsync<Application.Exceptions.AppException>(
            () => service.GetAiCreditPacksAsync(userId));
    }

    [Fact]
    public async Task CapturePayPalAiCreditOrder_GrantsCredits_ForProUser_MockMode()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithPlanAsync(db, userId, "pro", monthlyAiCredits: 150);

        var service = CreatePaymentService(db);

        var created = await service.CreatePayPalAiCreditOrderAsync(
            userId,
            new PayPalCreateAiCreditOrderRequest { PackCode = "pack_50" });

        var captured = await service.CapturePayPalAiCreditOrderAsync(
            userId,
            new PayPalCaptureOrderRequest { OrderId = created.OrderId });

        Assert.Equal(30, captured.CreditsGranted);
        Assert.Equal(180, captured.AiCreditsBalance);

        var purchaseEntry = await db.CreditLedgerEntries.SingleAsync(
            e => e.UserId == userId && e.Reason == "purchase");
        Assert.Equal("ai_purchased", purchaseEntry.CreditType);
    }

    [Fact]
    public async Task MonthlyReset_PreservesPurchasedCredits()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithPlanAsync(db, userId, "pro", monthlyAiCredits: 150);

        var lastMonth = DateTime.UtcNow.AddMonths(-1);
        var planEntry = await db.CreditLedgerEntries.SingleAsync(
            e => e.UserId == userId && e.CreditType == "ai");
        planEntry.CreatedAt = lastMonth;
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = -140,
            BalanceAfter = 10,
            Reason = "consume",
            CreatedAt = DateTime.UtcNow,
        });
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai_purchased",
            Delta = 50,
            BalanceAfter = 50,
            Reason = "purchase",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var billing = BillingTestHelpers.CreateService(db);
        var result = await billing.GetMyBillingAsync(userId);

        Assert.Equal(150, await GetBalanceAsync(db, userId, "ai"));
        Assert.Equal(50, await GetBalanceAsync(db, userId, "ai_purchased"));
        Assert.Equal(200, result.Credits.AiCredits);
    }

    private static Task<int> GetBalanceAsync(
        CraftQuestDbContext db,
        Guid userId,
        string creditType) =>
        db.CreditLedgerEntries
            .Where(e => e.UserId == userId && e.CreditType == creditType)
            .SumAsync(e => e.Delta);

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static PaymentService CreatePaymentService(CraftQuestDbContext db)
    {
        var billing = BillingTestHelpers.CreateService(db);
        var paymentOptions = Options.Create(new PaymentOptions
        {
            UseMockPayments = true,
            AiCreditPacks =
            [
                new AiCreditPackDefinition
                {
                    Code = "pack_50",
                    Name = "~5 AI generations",
                    Credits = 30,
                    PriceUsd = 4.99m,
                    SortOrder = 1,
                },
            ],
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

    private static async Task SeedUserWithPlanAsync(
        CraftQuestDbContext db,
        Guid userId,
        string planCode,
        int monthlyAiCredits)
    {
        var planId = planCode == "free" ? 1 : 2;
        db.Users.Add(new User
        {
            UserId = userId,
            Email = $"{userId:N}@test.com",
            PasswordHash = [1],
            DisplayName = "Test",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        db.Plans.Add(new Plan
        {
            PlanId = planId,
            Code = planCode,
            Name = planCode,
            IsActive = true,
            MonthlyAiCredits = monthlyAiCredits,
        });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = planId,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        if (monthlyAiCredits > 0)
        {
            db.CreditLedgerEntries.Add(new CreditLedgerEntry
            {
                CreditLedgerId = Guid.NewGuid(),
                UserId = userId,
                CreditType = "ai",
                Delta = monthlyAiCredits,
                BalanceAfter = monthlyAiCredits,
                Reason = "grant_plan",
                CreatedAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync();
    }

    private sealed class HttpClientFactoryStub : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new();
    }
}
