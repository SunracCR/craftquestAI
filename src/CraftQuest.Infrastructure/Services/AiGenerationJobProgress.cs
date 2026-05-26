using CraftQuest.Application.Contracts;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public sealed class AiGenerationJobProgress(CraftQuestDbContext dbContext) : IAiGenerationJobProgress
{
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

        var clamped = progressPercent.HasValue
            ? Math.Clamp(progressPercent.Value, 0, 100)
            : (int?)null;

        await dbContext.AiJobs
            .Where(j => j.AiJobId == _aiJobId.Value)
            .ExecuteUpdateAsync(
                s => s
                    .SetProperty(j => j.Stage, stage)
                    .SetProperty(j => j.ProgressPercent, clamped),
                cancellationToken);
    }
}
