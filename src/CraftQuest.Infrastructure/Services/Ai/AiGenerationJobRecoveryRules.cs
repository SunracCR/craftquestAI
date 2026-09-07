using CraftQuest.Application;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Infrastructure.Services.Ai;

internal static class AiGenerationJobRecoveryRules
{
    internal enum RecoveryAction
    {
        None,
        MarkFailed,
        MarkCompleted,
    }

    internal static RecoveryAction Evaluate(
        AiJob job,
        DateTime utcNow,
        AiGenerationOptions options,
        int pendingQueueCutoffMinutes)
    {
        if (!string.Equals(job.JobType, "generate_quiz", StringComparison.Ordinal)
            || job.CompletedAt is not null)
        {
            return RecoveryAction.None;
        }

        if (job.QuestionImportBatchId.HasValue)
        {
            return string.Equals(job.Status, "completed", StringComparison.Ordinal)
                ? RecoveryAction.None
                : RecoveryAction.MarkCompleted;
        }

        if (job.Status is not ("processing" or "pending" or "pending_retry"))
        {
            return RecoveryAction.None;
        }

        var pendingCutoff = utcNow.AddMinutes(-Math.Max(1, pendingQueueCutoffMinutes));
        var processingCutoff = utcNow.AddMinutes(
            -Math.Max(5, options.GenerationJobTimeoutMaxMinutes));

        var isAbandoned = job.Status switch
        {
            "processing" => job.StartedAt.HasValue
                ? job.StartedAt.Value < processingCutoff
                : job.CreatedAt < pendingCutoff,
            "pending" or "pending_retry" => job.CreatedAt < pendingCutoff,
            _ => false,
        };

        return isAbandoned ? RecoveryAction.MarkFailed : RecoveryAction.None;
    }

    internal static void Apply(
        AiJob job,
        RecoveryAction action,
        DateTime utcNow,
        string staleFailureMessage)
    {
        switch (action)
        {
            case RecoveryAction.MarkCompleted:
                job.Status = "completed";
                job.Stage = AiJobStages.Completed;
                job.ProgressPercent = 100;
                job.CompletedAt = utcNow;
                job.ErrorCode = null;
                job.ErrorMessage = null;
                job.NextRetryAt = null;
                break;
            case RecoveryAction.MarkFailed:
                job.Status = "failed";
                job.Stage = AiJobStages.Failed;
                job.ProgressPercent = null;
                job.ErrorCode = "GENERATION_STALE_ABORTED";
                job.ErrorMessage = staleFailureMessage;
                job.CompletedAt = utcNow;
                job.NextRetryAt = null;
                break;
        }
    }
}
