using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Services.Ai;

namespace CraftQuest.UnitTests.Ai;

public class AiGenerationJobRecoveryRulesTests
{
    private static readonly AiGenerationOptions DefaultOptions = new()
    {
        GenerationJobTimeoutMaxMinutes = 25,
        StaleProcessingMinutes = 12,
        StaleProcessingMinutesOnStart = 8,
    };

    [Fact]
    public void Evaluate_DoesNotFailRecentlyStartedProcessingJob()
    {
        var now = DateTime.UtcNow;
        var job = CreateJob(
            status: "processing",
            createdAt: now.AddMinutes(-15),
            startedAt: now.AddMinutes(-5));

        var action = AiGenerationJobRecoveryRules.Evaluate(
            job,
            now,
            DefaultOptions,
            pendingQueueCutoffMinutes: 12);

        Assert.Equal(AiGenerationJobRecoveryRules.RecoveryAction.None, action);
    }

    [Fact]
    public void Evaluate_FailsProcessingJobPastMaxTimeout()
    {
        var now = DateTime.UtcNow;
        var job = CreateJob(
            status: "processing",
            createdAt: now.AddMinutes(-40),
            startedAt: now.AddMinutes(-30));

        var action = AiGenerationJobRecoveryRules.Evaluate(
            job,
            now,
            DefaultOptions,
            pendingQueueCutoffMinutes: 12);

        Assert.Equal(AiGenerationJobRecoveryRules.RecoveryAction.MarkFailed, action);
    }

    [Fact]
    public void Evaluate_CompletesJobThatAlreadyHasImportBatch()
    {
        var now = DateTime.UtcNow;
        var job = CreateJob(
            status: "processing",
            createdAt: now.AddMinutes(-20),
            startedAt: now.AddMinutes(-18),
            importBatchId: Guid.NewGuid());

        var action = AiGenerationJobRecoveryRules.Evaluate(
            job,
            now,
            DefaultOptions,
            pendingQueueCutoffMinutes: 12);

        Assert.Equal(AiGenerationJobRecoveryRules.RecoveryAction.MarkCompleted, action);
    }

    [Fact]
    public void Evaluate_DoesNotFailPendingJobBeforeQueueCutoff()
    {
        var now = DateTime.UtcNow;
        var job = CreateJob(
            status: "pending",
            createdAt: now.AddMinutes(-5));

        var action = AiGenerationJobRecoveryRules.Evaluate(
            job,
            now,
            DefaultOptions,
            pendingQueueCutoffMinutes: 12);

        Assert.Equal(AiGenerationJobRecoveryRules.RecoveryAction.None, action);
    }

    private static AiJob CreateJob(
        string status,
        DateTime createdAt,
        DateTime? startedAt = null,
        Guid? importBatchId = null)
    {
        return new AiJob
        {
            AiJobId = Guid.NewGuid(),
            RequestedByUserId = Guid.NewGuid(),
            JobType = "generate_quiz",
            Status = status,
            CreatedAt = createdAt,
            StartedAt = startedAt,
            QuestionImportBatchId = importBatchId,
        };
    }
}
