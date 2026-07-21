using CraftQuest.Application.Exceptions;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.PrepPlus;

public class PrepPlusAccessServiceTests
{
    [Fact]
    public async Task GrantLifetimeAccess_ReplacesActiveTemporal()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var catalogItemId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            AccessType = "purchase",
            GrantedAt = now.AddDays(-5),
            ExpiresAt = now.AddDays(25),
            IsLifetimeAccess = false,
            PrepCatalogItemId = catalogItemId,
        });
        await db.SaveChangesAsync();

        var service = new PrepPlusAccessService(db);
        var grant = await service.GrantOrExtendPurchaseAccessAsync(
            userId,
            catalogItemId,
            quizId,
            isLifetimeAccess: true,
            durationDays: 0,
            purchaseId: null);

        Assert.True(grant.IsLifetimeAccess);
        Assert.Null(grant.AccessExpiresAt);

        var access = await db.QuizAccesses.SingleAsync(a => a.UserId == userId && a.QuizId == quizId);
        Assert.True(access.IsLifetimeAccess);
        Assert.Null(access.ExpiresAt);
    }

    [Fact]
    public async Task GrantTemporal_WhenOwned_ThrowsAlreadyOwned()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var catalogItemId = Guid.NewGuid();
        var quizId = Guid.NewGuid();

        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            AccessType = "purchase",
            GrantedAt = DateTime.UtcNow,
            ExpiresAt = null,
            IsLifetimeAccess = true,
            PrepCatalogItemId = catalogItemId,
        });
        await db.SaveChangesAsync();

        var service = new PrepPlusAccessService(db);

        var ex = await Assert.ThrowsAsync<AppException>(() =>
            service.GrantOrExtendPurchaseAccessAsync(
                userId,
                catalogItemId,
                quizId,
                isLifetimeAccess: false,
                durationDays: 30,
                purchaseId: null));

        Assert.Equal(PrepPlusErrorCodes.AlreadyOwned, ex.ErrorCode);
    }

    [Fact]
    public async Task GrantTemporal_ExtendsFromCurrentExpiry()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var catalogItemId = Guid.NewGuid();
        var quizId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var currentExpiry = now.AddDays(10);

        db.QuizAccesses.Add(new QuizAccess
        {
            QuizAccessId = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            AccessType = "purchase",
            GrantedAt = now.AddDays(-20),
            ExpiresAt = currentExpiry,
            IsLifetimeAccess = false,
            PrepCatalogItemId = catalogItemId,
        });
        await db.SaveChangesAsync();

        var service = new PrepPlusAccessService(db);
        var grant = await service.GrantOrExtendPurchaseAccessAsync(
            userId,
            catalogItemId,
            quizId,
            isLifetimeAccess: false,
            durationDays: 30,
            purchaseId: null);

        Assert.False(grant.IsLifetimeAccess);
        Assert.Equal(currentExpiry.AddDays(30), grant.AccessExpiresAt);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new CraftQuestDbContext(options);
    }
}
