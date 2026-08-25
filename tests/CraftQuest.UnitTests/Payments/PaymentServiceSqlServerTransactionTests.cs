using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Payments;
using CraftQuest.UnitTests.Billing;
using CraftQuest.UnitTests.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Payments;

/// <summary>
/// Validates that mobile credit verification completes when SQL Server retry strategy is enabled.
/// Requires LocalDB or CRAFTQUEST_TEST_SQLSERVER connection string; skips silently if unavailable.
/// </summary>
public class PaymentServiceSqlServerTransactionTests
{
    [Fact]
    public async Task VerifyMobileAiCreditPurchase_CompletesTransaction_WithSqlServerRetryStrategy()
    {
        await using var db = await TryCreateSqlServerDbAsync();
        if (db is null)
        {
            return;
        }

        var userId = Guid.NewGuid();
        await SeedProUserAsync(db, userId);

        var service = CreatePaymentService(db);

        var result = await service.VerifyMobileAiCreditPurchaseAsync(
            userId,
            new VerifyMobileAiCreditPurchaseRequest
            {
                Platform = "app_store",
                ProductId = "craftquest_ai_credits_50",
                PurchaseToken = "sandbox-jws-token",
                TransactionId = $"tx-{Guid.NewGuid():N}",
            });

        Assert.Equal("pack_50", result.PackCode);
        Assert.Equal(30, result.CreditsGranted);
        Assert.Equal("validated", result.Status);

        var purchase = await db.Purchases.SingleAsync(
            p => p.UserId == userId && p.ProductType == "ai_credits");
        Assert.Equal("validated", purchase.Status);
    }

    private static async Task<CraftQuestDbContext?> TryCreateSqlServerDbAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("CRAFTQUEST_TEST_SQLSERVER")
            ?? "Server=(localdb)\\mssqldblocaldb;Database=CraftQuest_PaymentTxTest;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

        try
        {
            var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
                .UseSqlServer(
                    connectionString,
                    sql => sql.EnableRetryOnFailure(
                        maxRetryCount: 3,
                        maxRetryDelay: TimeSpan.FromSeconds(1),
                        errorNumbersToAdd: null))
                .Options;

            var db = new CraftQuestDbContext(options);
            if (!await db.Database.CanConnectAsync())
            {
                await db.DisposeAsync();
                return null;
            }

            await db.Database.EnsureCreatedAsync();
            return db;
        }
        catch
        {
            return null;
        }
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
                    GooglePlayProductId = "craftquest_ai_credits_50",
                    AppStoreProductId = "craftquest_ai_credits_50",
                },
            ],
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
            new NoOpNotificationService(),
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

    private static async Task SeedProUserAsync(CraftQuestDbContext db, Guid userId)
    {
        if (!await db.Plans.AnyAsync(p => p.Code == "pro"))
        {
            db.Plans.Add(new Plan
            {
                PlanId = 2,
                Code = "pro",
                Name = "Pro",
                IsActive = true,
                MonthlyAiCredits = 150,
            });
        }

        db.Users.Add(new User
        {
            UserId = userId,
            Email = $"{userId:N}@test.com",
            PasswordHash = [1],
            DisplayName = "Test",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 2,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        });

        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = 150,
            BalanceAfter = 150,
            Reason = "grant_plan",
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
    }

    private sealed class HttpClientFactoryStub : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new();
    }
}
