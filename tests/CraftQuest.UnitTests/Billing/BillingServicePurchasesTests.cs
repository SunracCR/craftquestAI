using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.UnitTests.Billing;

public class BillingServicePurchasesTests
{
    [Fact]
    public async Task GetMyPurchasesAsync_ReturnsOnlyCurrentUser_OrderedByPurchasedAt()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var otherUserId = Guid.NewGuid();
        await SeedUserAndPlanAsync(db, userId, planCode: "pro", planName: "Pro");
        await SeedUserAndPlanAsync(db, otherUserId, planCode: "free", planName: "Free");

        var olderId = Guid.NewGuid();
        var newerId = Guid.NewGuid();
        db.Purchases.AddRange(
            new Purchase
            {
                PurchaseId = olderId,
                UserId = userId,
                ProductCode = "pro",
                ProductType = "subscription",
                ProviderCode = "paypal",
                Amount = 4.99m,
                CurrencyCode = "USD",
                Status = "validated",
                PurchasedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            },
            new Purchase
            {
                PurchaseId = newerId,
                UserId = userId,
                ProductCode = "pro",
                ProductType = "subscription",
                ProviderCode = "paypal",
                Amount = 4.99m,
                CurrencyCode = "USD",
                Status = "validated",
                PurchasedAt = new DateTime(2026, 3, 1, 0, 0, 0, DateTimeKind.Utc),
                CreatedAt = new DateTime(2026, 3, 1, 0, 0, 0, DateTimeKind.Utc),
            },
            new Purchase
            {
                PurchaseId = Guid.NewGuid(),
                UserId = otherUserId,
                ProductCode = "pro",
                ProductType = "subscription",
                ProviderCode = "paypal",
                Status = "validated",
                PurchasedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
            });
        await db.SaveChangesAsync();

        var billing = new BillingService(db);
        var purchases = await billing.GetMyPurchasesAsync(userId);

        Assert.Equal(2, purchases.Count);
        Assert.Equal(newerId, purchases[0].PurchaseId);
        Assert.Equal(olderId, purchases[1].PurchaseId);
        Assert.All(purchases, p => Assert.Equal("Pro", p.ProductDisplayName));
    }

    [Fact]
    public async Task GetMyPurchasesAsync_Empty_ReturnsEmptyList()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        await SeedUserAndPlanAsync(db, userId, planCode: "free", planName: "Free");

        var billing = new BillingService(db);
        var purchases = await billing.GetMyPurchasesAsync(userId);

        Assert.Empty(purchases);
    }

    private static CraftQuestDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new CraftQuestDbContext(options);
    }

    private static async Task SeedUserAndPlanAsync(
        CraftQuestDbContext db,
        Guid userId,
        string planCode,
        string planName)
    {
        var planId = planCode == "pro" ? 2 : 1;
        if (!await db.Plans.AnyAsync(p => p.PlanId == planId))
        {
            db.Plans.Add(new Plan
            {
                PlanId = planId,
                Code = planCode,
                Name = planName,
                IsActive = true,
                MonthlyAiCredits = planCode == "pro" ? 150 : 20,
            });
        }

        db.Users.Add(new User
        {
            UserId = userId,
            Email = $"{userId:N}@test.com",
            PasswordHash = [1],
            DisplayName = "User",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
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

        await db.SaveChangesAsync();
    }
}
