using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.UnitTests.Payments;

public class PaymentServiceMockTests
{
    [Fact]
    public async Task CapturePayPalOrder_InMockMode_ActivatesPlan()
    {
        await using var db = CreateDb();
        await SeedPlansAndUserAsync(db);
        var userId = await db.Users.Select(u => u.UserId).FirstAsync();

        var billing = new BillingService(db);
        var paymentOptions = Options.Create(new PaymentOptions { UseMockPayments = true });
        var service = new PaymentService(
            db,
            billing,
            new PayPalApiClient(new HttpClient(), paymentOptions),
            paymentOptions);

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
