using CraftQuest.Application.Exceptions;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Billing;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServiceQuizModificationTests
{
    [Fact]
    public async Task EnsureCanModifyOwnedQuizzesAsync_FreeWithTwoQuizzes_AllowsModification()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, maxQuizzes: 2);
        await SeedOwnedQuizzesAsync(db, userId, count: 2);

        var billing = BillingTestHelpers.CreateService(db);
        await billing.EnsureCanModifyOwnedQuizzesAsync(userId);
    }

    [Fact]
    public async Task EnsureCanModifyOwnedQuizzesAsync_FreeWithThreeQuizzes_BlocksModification()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, maxQuizzes: 2);
        await SeedOwnedQuizzesAsync(db, userId, count: 3);

        var billing = BillingTestHelpers.CreateService(db);
        var ex = await Assert.ThrowsAsync<AppException>(
            () => billing.EnsureCanModifyOwnedQuizzesAsync(userId));

        Assert.Equal("QUIZ_OVER_PLAN_LIMIT", ex.ErrorCode);
        Assert.Equal(2, ex.Metadata?["maxQuizzes"]);
        Assert.Equal(3, ex.Metadata?["currentQuizzes"]);
    }

    [Fact]
    public async Task EnsureCanModifyOwnedQuizzesAsync_ProWithManyQuizzes_AllowsModification()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithProPlanAsync(db, userId);
        await SeedOwnedQuizzesAsync(db, userId, count: 10);

        var billing = BillingTestHelpers.CreateService(db);
        await billing.EnsureCanModifyOwnedQuizzesAsync(userId);
    }

    [Fact]
    public async Task GetMyBillingAsync_FreeOverQuizLimit_SetsQuizModificationLocked()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserWithFreePlanAsync(db, userId, maxQuizzes: 2);
        await SeedOwnedQuizzesAsync(db, userId, count: 5);

        var billing = BillingTestHelpers.CreateService(db);
        var result = await billing.GetMyBillingAsync(userId);

        Assert.True(result.Entitlements.QuizModificationLocked);
        Assert.Equal(5, result.Usage.QuizzesCreated);
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
        int maxQuizzes = 2)
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
            MaxQuizzes = maxQuizzes,
            MaxQuestionsPerQuiz = 50,
            MonthlyAiCredits = 20,
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

    private static async Task SeedUserWithProPlanAsync(CraftQuestDbContext db, Guid userId)
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
            MaxQuizzes = null,
            MonthlyAiCredits = 150,
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
        await db.SaveChangesAsync();
    }

    private static async Task SeedOwnedQuizzesAsync(
        CraftQuestDbContext db,
        Guid userId,
        int count)
    {
        for (var i = 0; i < count; i++)
        {
            db.Quizzes.Add(new Quiz
            {
                QuizId = Guid.NewGuid(),
                CreatedByUserId = userId,
                Title = $"Quiz {i + 1}",
                CreatedAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync();
    }
}
