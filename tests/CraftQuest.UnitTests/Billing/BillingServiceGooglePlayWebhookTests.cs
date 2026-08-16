using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServiceGooglePlayWebhookTests
{
    [Fact]
    public async Task RevokeSubscriptionImmediatelyAsync_DowngradesUserToFree()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedPlansAsync(db);
        await SeedGooglePlaySubscriptionAsync(db, userId, "revoke-token");

        var billing = BillingTestHelpers.CreateService(db);
        await billing.RevokeSubscriptionImmediatelyAsync("revoke-token", "google_play");

        var active = await db.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .SingleAsync();

        Assert.Equal("free", active.Plan.Code);
        Assert.True(
            await db.UserSubscriptions.AnyAsync(s =>
                s.UserId == userId
                && s.ProviderSubscriptionId == "revoke-token"
                && s.Status == SubscriptionStatuses.Cancelled));
    }

    [Fact]
    public async Task RenewSubscriptionPeriodAsync_WithPeriodEnd_UsesGoogleExpiryAndClearsPaymentIssue()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedPlansAsync(db);
        var subscriptionId = await SeedGooglePlaySubscriptionAsync(db, userId, "renew-token");
        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        subscription!.PaymentIssuePending = true;
        await db.SaveChangesAsync();

        var googleExpiry = DateTime.UtcNow.AddDays(28);
        var billing = BillingTestHelpers.CreateService(db);
        await billing.RenewSubscriptionPeriodAsync(
            "renew-token",
            "google_play",
            googleExpiry,
            "order-123");

        await db.Entry(subscription).ReloadAsync();
        Assert.Equal(googleExpiry, subscription.EndsAt);
        Assert.False(subscription.PaymentIssuePending);
        Assert.True(subscription.AutoRenewEnabled);
        Assert.False(subscription.CancelAtPeriodEnd);
    }

    [Fact]
    public async Task EnsureHasAiCreditsAsync_WhenPaymentIssuePending_Throws402()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedPlansAsync(db);
        var subscriptionId = await SeedGooglePlaySubscriptionAsync(db, userId, "hold-token");
        var subscription = await db.UserSubscriptions.FindAsync(subscriptionId);
        subscription!.PaymentIssuePending = true;
        await db.SaveChangesAsync();

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

        var billing = BillingTestHelpers.CreateService(db);
        var ex = await Assert.ThrowsAsync<AppException>(
            () => billing.EnsureHasAiCreditsAsync(userId, 1));

        Assert.Equal(402, ex.StatusCode);
        Assert.Equal("PAYMENT_ISSUE_PENDING", ex.ErrorCode);
    }

    private static CraftQuestDbContext CreateDb() =>
        new(new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private static async Task SeedPlansAsync(CraftQuestDbContext db)
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
        await db.SaveChangesAsync();
    }

    private static async Task<Guid> SeedGooglePlaySubscriptionAsync(
        CraftQuestDbContext db,
        Guid userId,
        string purchaseToken)
    {
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
}
