using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Billing;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServiceCreditTests
{
    [Fact]
    public async Task ActivatePlanAsync_SetsBalanceToPlanAmount_DoesNotAccumulate()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, monthlyAiCredits: 20, maxQuizzes: 2, maxQuestionsPerQuiz: 50);

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
        await SeedUserWithFreePlanAsync(db, userId, monthlyAiCredits: 20, maxQuizzes: 2, maxQuestionsPerQuiz: 50);

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

    [Fact]
    public async Task GetMyBillingAsync_ProPlan_DoesNotResetAtCalendarMonthBoundary()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var startedAt = DateTime.UtcNow.AddDays(-3);

        db.Users.Add(new User
        {
            UserId = userId,
            Email = "pro@test.com",
            PasswordHash = [1],
            DisplayName = "Pro",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        db.Plans.Add(new Plan
        {
            PlanId = 2,
            Code = "pro",
            Name = "Pro",
            IsActive = true,
            MonthlyAiCredits = 150,
        });
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 2,
            Status = "active",
            StartedAt = startedAt,
            EndsAt = startedAt.AddMonths(1),
            ProviderCode = "paypal",
            ProviderSubscriptionId = "sub-1",
            CreatedAt = startedAt,
            BillingCycle = "monthly",
            AutoRenewEnabled = true,
        });
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = 150,
            BalanceAfter = 150,
            Reason = "grant_plan",
            CreatedAt = startedAt,
        });
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = -150,
            BalanceAfter = 0,
            Reason = "consume",
            CreatedAt = startedAt.AddHours(1),
        });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        var result = await billing.GetMyBillingAsync(userId);

        Assert.Equal(0, result.Credits.AiCredits);
        Assert.False(
            await db.CreditLedgerEntries.AnyAsync(
                e => e.UserId == userId && e.Reason == "monthly_reset"));
    }

    [Fact]
    public async Task GetMyBillingAsync_ProPlan_ResetsAfterBillingPeriodEnds()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var subscription = new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 2,
            Status = "active",
            StartedAt = new DateTime(2026, 4, 15, 0, 0, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 6, 15, 0, 0, 0, DateTimeKind.Utc),
            ProviderCode = "paypal",
            ProviderSubscriptionId = "sub-2",
            CreatedAt = new DateTime(2026, 4, 15, 0, 0, 0, DateTimeKind.Utc),
            BillingCycle = "monthly",
            AutoRenewEnabled = true,
        };
        var plan = new Plan
        {
            PlanId = 2,
            Code = "pro",
            Name = "Pro",
            IsActive = true,
            MonthlyAiCredits = 150,
        };
        subscription.Plan = plan;

        var currentPeriodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            DateTime.UtcNow);

        db.Users.Add(new User
        {
            UserId = userId,
            Email = "pro2@test.com",
            PasswordHash = [1],
            DisplayName = "Pro2",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        db.Plans.Add(plan);
        db.UserSubscriptions.Add(subscription);
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = 150,
            BalanceAfter = 150,
            Reason = "grant_plan",
            CreatedAt = currentPeriodStart.AddDays(-2),
        });
        db.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = -150,
            BalanceAfter = 0,
            Reason = "consume",
            CreatedAt = currentPeriodStart.AddDays(-1),
        });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        var result = await billing.GetMyBillingAsync(userId);

        Assert.Equal(150, result.Credits.AiCredits);
        Assert.True(
            await db.CreditLedgerEntries.AnyAsync(
                e => e.UserId == userId && e.Reason == "monthly_reset"));
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    [Fact]
    public async Task GetQuizQuestionCapacityAsync_FreePlan_UsesPlanLimit()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, monthlyAiCredits: 20);

        var quizId = Guid.NewGuid();
        db.Quizzes.Add(new Quiz
        {
            QuizId = quizId,
            CreatedByUserId = userId,
            Title = "Test",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        var capacity = await billing.GetQuizQuestionCapacityAsync(userId, quizId);

        Assert.Equal(2, (await db.Plans.FirstAsync(p => p.Code == "free")).MaxQuizzes);
        Assert.Equal(50, capacity.MaxQuestionsPerQuiz);
        Assert.Equal(50, capacity.RemainingSlots);
    }

    private static async Task SeedUserWithFreePlanAsync(
        CraftQuestDbContext db,
        Guid userId,
        int monthlyAiCredits,
        int maxQuizzes = 2,
        int maxQuestionsPerQuiz = 50)
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
            MaxQuizzes = maxQuizzes,
            MaxQuestionsPerQuiz = maxQuestionsPerQuiz,
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
