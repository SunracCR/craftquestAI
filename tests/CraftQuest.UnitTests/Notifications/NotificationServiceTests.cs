using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.UnitTests.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;

namespace CraftQuest.UnitTests.Notifications;

public class NotificationServiceTests
{
    [Fact]
    public async Task NotifyAsync_PersistsInAppNotification()
    {
        await using var db = CreateDb();
        var userId = await SeedUserAsync(db, "es");
        var service = CreateService(db);

        await service.NotifyAsync(
            userId,
            NotificationTypes.ClassJoined,
            new NotificationPayload { ClassName = "Math 101" },
            $"class_joined:{userId}");

        var stored = await db.Notifications.SingleAsync();
        Assert.Equal(userId, stored.UserId);
        Assert.Equal(NotificationTypes.ClassJoined, stored.Type);
        Assert.False(stored.IsRead);
        Assert.Contains("Math 101", stored.Body);
    }

    [Fact]
    public async Task NotifyAsync_WithDedupKey_SkipsDuplicate()
    {
        await using var db = CreateDb();
        var userId = await SeedUserAsync(db, "en");
        var service = CreateService(db);
        const string dedup = "assignment_due_soon:1";

        await service.NotifyAsync(
            userId,
            NotificationTypes.AssignmentDueSoon,
            new NotificationPayload { AssignmentTitle = "Task A", DueAtLabel = "2026-06-26" },
            dedup);
        await service.NotifyAsync(
            userId,
            NotificationTypes.AssignmentDueSoon,
            new NotificationPayload { AssignmentTitle = "Task A", DueAtLabel = "2026-06-26" },
            dedup);

        Assert.Equal(1, await db.Notifications.CountAsync());
    }

    [Fact]
    public async Task EnqueueFanOutAsync_AddsPendingOutboxRow()
    {
        await using var db = CreateDb();
        var service = CreateService(db);

        await service.EnqueueFanOutAsync(
            NotificationOutboxEventTypes.AssignmentCreated,
            """{"assignmentId":"11111111-1111-1111-1111-111111111111","classId":"22222222-2222-2222-2222-222222222222"}""");

        var outbox = await db.NotificationOutbox.SingleAsync();
        Assert.Equal("pending", outbox.Status);
        Assert.Equal(NotificationOutboxEventTypes.AssignmentCreated, outbox.EventType);
    }

    [Fact]
    public async Task MarkReadAsync_SetsReadState()
    {
        await using var db = CreateDb();
        var userId = await SeedUserAsync(db, "es");
        var service = CreateService(db);
        await service.NotifyAsync(
            userId,
            NotificationTypes.QuizShared,
            new NotificationPayload { QuizTitle = "Quiz" });

        var notificationId = await db.Notifications.Select(n => n.NotificationId).SingleAsync();
        await service.MarkReadAsync(userId, notificationId);

        var entity = await db.Notifications.SingleAsync();
        Assert.True(entity.IsRead);
        Assert.NotNull(entity.ReadAt);
    }

    [Fact]
    public async Task CountUnreadAsync_ReturnsUnreadOnly()
    {
        await using var db = CreateDb();
        var userId = await SeedUserAsync(db, "es");
        var service = CreateService(db);

        await service.NotifyAsync(userId, NotificationTypes.QuizShared, new NotificationPayload());
        await service.NotifyAsync(userId, NotificationTypes.ClassJoined, new NotificationPayload());

        var firstId = await db.Notifications.OrderBy(n => n.CreatedAt).Select(n => n.NotificationId).FirstAsync();
        await service.MarkReadAsync(userId, firstId);

        var count = await service.CountUnreadAsync(userId);
        Assert.Equal(1, count);
    }

    private static NotificationService CreateService(CraftQuestDbContext db)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddScoped(_ => db);
        services.AddSingleton<IEmailSender, CapturingEmailSender>();
        services.AddSingleton<IPushSender, NoOpPushSender>();
        services.AddScoped<NotificationService>();
        var provider = services.BuildServiceProvider();
        return provider.GetRequiredService<NotificationService>();
    }

    private static CraftQuestDbContext CreateDb() =>
        new(new DbContextOptionsBuilder<CraftQuestDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private static async Task<Guid> SeedUserAsync(CraftQuestDbContext db, string language)
    {
        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "user@test.local",
            EmailNormalized = "user@test.local",
            PreferredLanguage = language,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        return userId;
    }
}
