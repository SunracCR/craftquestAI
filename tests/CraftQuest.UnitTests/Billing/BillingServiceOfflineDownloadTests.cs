using CraftQuest.Application.Exceptions;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServiceOfflineDownloadTests
{
    [Fact]
    public async Task EnsureCanDownloadOfflineAsync_FreeWithoutQuizId_Throws()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId);

        var billing = BillingTestHelpers.CreateService(db);

        var ex = await Assert.ThrowsAsync<AppException>(
            () => billing.EnsureCanDownloadOfflineAsync(userId));

        Assert.Equal("OFFLINE_PLAN_REQUIRED", ex.ErrorCode);
    }

    [Fact]
    public async Task EnsureCanDownloadOfflineAsync_FreeWithPrepPurchase_AllowsDownloadForThatQuiz()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId);
        await SeedPrepPurchaseAccessAsync(db, userId, quizId);

        var billing = BillingTestHelpers.CreateService(db);

        await billing.EnsureCanDownloadOfflineAsync(userId, quizId);
    }

    [Fact]
    public async Task EnsureCanDownloadOfflineAsync_ProPlan_AllowsWithoutQuizId()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithProPlanAsync(db, userId);

        var billing = BillingTestHelpers.CreateService(db);

        await billing.EnsureCanDownloadOfflineAsync(userId);
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
        Guid userId)
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
        });
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 1,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            ProviderCode = "internal",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
    }

    private static async Task SeedUserWithProPlanAsync(
        CraftQuestDbContext db,
        Guid userId)
    {
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
        });
        db.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = 2,
            Status = "active",
            StartedAt = DateTime.UtcNow,
            ProviderCode = "internal",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
    }

    private static async Task SeedPrepPurchaseAccessAsync(
        CraftQuestDbContext db,
        Guid userId,
        Guid quizId)
    {
        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            AccessType = "purchase",
            IsLifetimeAccess = false,
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            GrantedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
    }
}
