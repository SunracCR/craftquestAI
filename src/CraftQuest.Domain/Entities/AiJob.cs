namespace CraftQuest.Domain.Entities;

public class AiJob
{
    public Guid AiJobId { get; set; }
    public Guid RequestedByUserId { get; set; }
    public string JobType { get; set; } = string.Empty;
    public string Status { get; set; } = "pending";
    public Guid? StudyMaterialId { get; set; }
    public Guid? QuestionImportBatchId { get; set; }
    public Guid? TargetQuizId { get; set; }
    public string? ModelName { get; set; }
    public string? PromptVersion { get; set; }
    public int? InputTokens { get; set; }
    public int? OutputTokens { get; set; }
    public decimal? EstimatedCostUsd { get; set; }
    public int? CreditsConsumed { get; set; }
    public string? InputJson { get; set; }
    public string? ResultJson { get; set; }
    public string? ErrorMessage { get; set; }
    public string? ErrorCode { get; set; }
    public DateTime? NextRetryAt { get; set; }
    public int RetryAttempt { get; set; }
    public string? Stage { get; set; }
    public int? ProgressPercent { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }

    public User RequestedByUser { get; set; } = null!;
}
