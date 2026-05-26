using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServiceCreditTests
{
    [Fact]
    public async Task ActivatePlanAsync_SetsBalanceToPlanAmount_DoesNotAccumulate()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, monthlyAiCredits: 20);

        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = 20,
            BalanceAfter = 20,
            Reason = "grant_plan",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        db.Plans.Add(new Plan
        {
            PlanId = 2,
            Code = "pro",
            Name = "Pro",
            IsActive = true,
            MonthlyAiCredits = 150,
        });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        await billing.ActivatePlanAsync(userId, "pro", "paypal", "order-1");

        var balance = await db.CreditLedgerEntries
            .Where(e => e.UserId == userId && e.CreditType == "ai")
            .SumAsync(e => e.Delta);

        Assert.Equal(150, balance);
    }

    [Fact]
    public async Task GetMyBillingAsync_NewMonth_ResetsUnusedCredits()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, monthlyAiCredits: 20);

        var lastMonth = DateTime.UtcNow.AddMonths(-1);
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = 20,
            BalanceAfter = 20,
            Reason = "grant_plan",
            CreatedAt = lastMonth,
        });
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = -5,
            BalanceAfter = 15,
            Reason = "consume",
            CreatedAt = lastMonth,
        });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        var result = await billing.GetMyBillingAsync(userId);

        Assert.Equal(20, result.Credits.AiCredits);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task SeedUserWithFreePlanAsync(
        CraftQuestDbContext db,
        Guid userId,
        int monthlyAiCredits)
    {
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "user@test.com",
            PasswordHash = [1],
            DisplayName = "User",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });

        db.Plans.Add(new Plan
        {
            PlanId = 1,
            Code = "free",
            Name = "Free",
            IsActive = true,
            MonthlyAiCredits = monthlyAiCredits,
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
