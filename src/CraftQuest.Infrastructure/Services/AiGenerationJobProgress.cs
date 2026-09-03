using CraftQuest.Application.Contracts;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services;

/// <summary>
/// Writes AI job progress on a dedicated DbContext so heartbeat ticks and
/// parallel chunk updates never share the generation scope connection.
/// Progress is best-effort: a failed tick must not abort generation.
/// </summary>
public sealed class AiGenerationJobProgress(
    IServiceScopeFactory scopeFactory,
    ILogger<AiGenerationJobProgress> logger) : IAiGenerationJobProgress
{
    private readonly SemaphoreSlim _updateGate = new(1, 1);
    private Guid? _aiJobId;

    public void Attach(Guid aiJobId) => _aiJobId = aiJobId;

    public void Detach() => _aiJobId = null;

    public async Task UpdateAsync(
        string stage,
        int? progressPercent,
        CancellationToken cancellationToken = default)
    {
        if (_aiJobId is null)
        {
            return;
        }

        var jobId = _aiJobId.Value;
        var clamped = progressPercent.HasValue
            ? Math.Clamp(progressPercent.Value, 0, 100)
            : (int?)null;

        try
        {
            await _updateGate.WaitAsync(cancellationToken);
        }
        catch (OperationCanceledException)
        {
            return;
        }

        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<CraftQuestDbContext>();
            await dbContext.AiJobs
                .Where(j => j.AiJobId == jobId)
                .ExecuteUpdateAsync(
                    s => s
                        .SetProperty(j => j.Stage, stage)
                        .SetProperty(j => j.ProgressPercent, clamped),
                    cancellationToken);
        }
        catch (OperationCanceledException)
        {
            // Progress is optional; cancellation should not fail the job.
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Could not persist AI job {JobId} progress ({Stage}, {Percent}%).",
                jobId,
                stage,
                clamped);
        }
        finally
        {
            _updateGate.Release();
        }
    }
}
