using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Application.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.HostedServices;

/// <summary>
/// Processes notification outbox fan-out and scheduled reminders (assignments, membership).
/// </summary>
public sealed class NotificationReminderHostedService(
    IServiceScopeFactory scopeFactory,
    ILogger<NotificationReminderHostedService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<CraftQuestDbContext>();
                var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();

                await ProcessOutboxAsync(dbContext, notifications, stoppingToken);
                await ProcessAssignmentDueSoonAsync(dbContext, notifications, stoppingToken);
                await ProcessMembershipExpiringAsync(dbContext, notifications, stoppingToken);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(ex, "Notification reminder job failed.");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    private static async Task ProcessOutboxAsync(
        CraftQuestDbContext dbContext,
        INotificationService notifications,
        CancellationToken cancellationToken)
    {
        var pending = await dbContext.NotificationOutbox
            .Where(o => o.Status == "pending")
            .OrderBy(o => o.CreatedAt)
            .Take(20)
            .ToListAsync(cancellationToken);

        foreach (var item in pending)
        {
            try
            {
                if (item.EventType == NotificationOutboxEventTypes.AssignmentCreated)
                {
                    var payload = JsonSerializer.Deserialize<AssignmentCreatedOutboxPayload>(
                        item.PayloadJson,
                        JsonOptions);
                    if (payload is not null)
                    {
                        await FanOutAssignmentCreatedAsync(
                            dbContext,
                            notifications,
                            payload,
                            cancellationToken);
                    }
                }

                item.Status = "processed";
                item.ProcessedAt = DateTime.UtcNow;
            }
            catch
            {
                item.Status = "failed";
                item.ProcessedAt = DateTime.UtcNow;
            }
        }

        if (pending.Count > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    private static async Task FanOutAssignmentCreatedAsync(
        CraftQuestDbContext dbContext,
        INotificationService notifications,
        AssignmentCreatedOutboxPayload payload,
        CancellationToken cancellationToken)
    {
        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Class)
            .FirstOrDefaultAsync(a => a.AssignmentId == payload.AssignmentId, cancellationToken);
        if (assignment is null)
        {
            return;
        }

        var quizTitle = await dbContext.Quizzes
            .AsNoTracking()
            .Where(q => q.QuizId == assignment.QuizId)
            .Select(q => q.Title)
            .FirstOrDefaultAsync(cancellationToken);

        var memberIds = await dbContext.ClassMembers
            .AsNoTracking()
            .Where(m => m.ClassId == assignment.ClassId && m.Status == "active")
            .Select(m => m.UserId)
            .ToListAsync(cancellationToken);

        var notificationPayload = new NotificationPayload
        {
            AssignmentId = assignment.AssignmentId,
            AssignmentTitle = assignment.Title,
            ClassId = assignment.ClassId,
            ClassName = assignment.Class?.Name,
            QuizId = assignment.QuizId,
            QuizTitle = quizTitle,
            Route = $"student/assignments/{assignment.AssignmentId}",
        };

        await notifications.NotifyManyAsync(
            memberIds,
            NotificationTypes.AssignmentCreated,
            notificationPayload,
            userId => $"assignment_created:{assignment.AssignmentId}:{userId}",
            cancellationToken);
    }

    private static async Task ProcessAssignmentDueSoonAsync(
        CraftQuestDbContext dbContext,
        INotificationService notifications,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var windowEnd = now.AddHours(24);

        var assignments = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Class)
            .Where(a => a.Status == "active"
                && a.DueAt != null
                && a.DueAt > now
                && a.DueAt <= windowEnd)
            .ToListAsync(cancellationToken);

        foreach (var assignment in assignments)
        {
            var memberIds = await dbContext.ClassMembers
                .AsNoTracking()
                .Where(m => m.ClassId == assignment.ClassId && m.Status == "active")
                .Select(m => m.UserId)
                .ToListAsync(cancellationToken);

            if (memberIds.Count == 0)
            {
                continue;
            }

            var completedUserIds = await dbContext.PracticeSessions
                .AsNoTracking()
                .Where(ps => ps.AssignmentId == assignment.AssignmentId
                    && ps.Status == "finished"
                    && ps.StudentUserId != null)
                .Select(ps => ps.StudentUserId!.Value)
                .Distinct()
                .ToListAsync(cancellationToken);

            var pendingMembers = memberIds.Except(completedUserIds).ToList();
            if (pendingMembers.Count == 0)
            {
                continue;
            }

            var dueLabel = assignment.DueAt!.Value.ToString("yyyy-MM-dd");
            var payload = new NotificationPayload
            {
                AssignmentId = assignment.AssignmentId,
                AssignmentTitle = assignment.Title,
                ClassId = assignment.ClassId,
                ClassName = assignment.Class?.Name,
                QuizId = assignment.QuizId,
                DueAtLabel = dueLabel,
                Route = $"student/assignments/{assignment.AssignmentId}",
            };

            await notifications.NotifyManyAsync(
                pendingMembers,
                NotificationTypes.AssignmentDueSoon,
                payload,
                userId => $"assignment_due_soon:{assignment.AssignmentId}:{userId}",
                cancellationToken);
        }
    }

    private static async Task ProcessMembershipExpiringAsync(
        CraftQuestDbContext dbContext,
        INotificationService notifications,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var threshold = now.AddDays(7);

        var subs = await dbContext.UserSubscriptions
            .AsNoTracking()
            .Include(s => s.Plan)
            .Where(s => s.Status == "active"
                && s.EndsAt != null
                && s.EndsAt > now
                && s.EndsAt <= threshold
                && s.Plan.Code != "free")
            .ToListAsync(cancellationToken);

        foreach (var sub in subs)
        {
            var daysRemaining = (int)Math.Ceiling((sub.EndsAt!.Value - now).TotalDays);
            if (daysRemaining is not (1 or 3 or 7))
            {
                continue;
            }

            var payload = new NotificationPayload
            {
                PlanName = sub.Plan.Name,
                DaysRemaining = daysRemaining,
                Route = "profile/billing",
            };

            await notifications.NotifyAsync(
                sub.UserId,
                NotificationTypes.MembershipExpiring,
                payload,
                $"membership_expiring:{sub.UserSubscriptionId}:{daysRemaining}",
                cancellationToken);
        }
    }
}
