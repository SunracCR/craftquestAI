using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using CraftQuest.Application.Options;

namespace CraftQuest.Infrastructure.HostedServices;

/// <summary>
/// Periodically executes lightweight reads against quiz/practice tables so their pages
/// stay in the SQL Server buffer pool after idle periods.
/// </summary>
public sealed class DatabaseKeepWarmHostedService(
    IServiceScopeFactory scopeFactory,
    IOptions<PracticeOptions> practiceOptions,
    ILogger<DatabaseKeepWarmHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!practiceOptions.Value.EnableDatabaseKeepWarm)
        {
            logger.LogInformation("Database keep-warm service is disabled.");
            return;
        }

        var intervalMinutes = Math.Clamp(practiceOptions.Value.KeepWarmIntervalMinutes, 1, 15);
        var interval = TimeSpan.FromMinutes(intervalMinutes);

        logger.LogInformation(
            "Database keep-warm service started with interval {IntervalMinutes} minutes.",
            intervalMinutes);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(interval, stoppingToken);
                await WarmAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Database keep-warm cycle failed.");
            }
        }
    }

    private async Task WarmAsync(CancellationToken cancellationToken)
    {
        using var scope = scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CraftQuestDbContext>();

        if (!dbContext.Database.IsSqlServer())
        {
            return;
        }

        await dbContext.Database.ExecuteSqlRawAsync(
            """
            SELECT TOP 1 q.QuestionId
            FROM quiz.Questions q WITH (NOLOCK)
            WHERE q.DeletedAt IS NULL
            ORDER BY q.QuestionId
            """,
            cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync(
            """
            SELECT TOP 1 o.AnswerOptionId
            FROM quiz.QuestionAnswerOptions o WITH (NOLOCK)
            WHERE o.IsActive = 1
            ORDER BY o.AnswerOptionId
            """,
            cancellationToken);

        await dbContext.Database.ExecuteSqlRawAsync(
            """
            SELECT TOP 1 ps.PracticeSessionId
            FROM practice.PracticeSessions ps WITH (NOLOCK)
            ORDER BY ps.StartedAt DESC
            """,
            cancellationToken);

        logger.LogDebug("Database keep-warm cycle completed.");
    }
}
