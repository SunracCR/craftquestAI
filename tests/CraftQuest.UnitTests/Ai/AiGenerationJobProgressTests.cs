using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Ai;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace CraftQuest.UnitTests.Ai;

public class AiGenerationJobProgressTests
{
    [Fact]
    public async Task UpdateAsync_FromParallelCallers_DoesNotThrow()
    {
        var dbName = Guid.NewGuid().ToString();
        await using var provider = CreateProvider(dbName);
        var jobId = await SeedJobAsync(provider);

        using var scope = provider.CreateScope();
        var progress = scope.ServiceProvider.GetRequiredService<IAiGenerationJobProgress>();
        progress.Attach(jobId);

        var updates = Enumerable.Range(0, 24).Select(i =>
            progress.UpdateAsync(AiJobStages.Generating, 20 + (i % 50)));

        var exception = await Record.ExceptionAsync(() => Task.WhenAll(updates));
        Assert.Null(exception);
    }

    [Fact]
    public async Task Heartbeat_WhenProgressThrows_DoesNotFailDispose()
    {
        var progress = new ThrowingProgress();
        await using var heartbeat = AiGenerationProgressHeartbeat.Start(
            progress,
            floorPercent: 28,
            ceilingPercent: 68,
            CancellationToken.None,
            tickInterval: TimeSpan.FromMilliseconds(20));

        await Task.Delay(80);
    }

    private static ServiceProvider CreateProvider(string dbName)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddDbContext<CraftQuestDbContext>(options =>
            options.UseInMemoryDatabase(dbName));
        services.AddScoped<IAiGenerationJobProgress, AiGenerationJobProgress>();
        return services.BuildServiceProvider();
    }

    private static async Task<Guid> SeedJobAsync(ServiceProvider provider)
    {
        using var scope = provider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<CraftQuestDbContext>();
        var userId = Guid.NewGuid();
        var jobId = Guid.NewGuid();
        db.Users.Add(new User
        {
            UserId = userId,
            Email = "progress@test.local",
            EmailNormalized = "progress@test.local",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        });
        db.AiJobs.Add(new AiJob
        {
            AiJobId = jobId,
            RequestedByUserId = userId,
            JobType = "generate_quiz",
            Status = "processing",
            Stage = AiJobStages.Preparing,
            ProgressPercent = 5,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        return jobId;
    }

    private sealed class ThrowingProgress : IAiGenerationJobProgress
    {
        public void Attach(Guid aiJobId)
        {
        }

        public void Detach()
        {
        }

        public Task UpdateAsync(
            string stage,
            int? progressPercent,
            CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException(
                "The connection was not closed. The connection's current state is connecting.");
    }
}
