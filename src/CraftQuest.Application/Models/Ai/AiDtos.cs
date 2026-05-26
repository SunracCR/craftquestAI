using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Models.Ai;

public class AiNormalizeRawTextRequest
{
    public string RawText { get; set; } = string.Empty;
    public string TargetFormat { get; set; } = "CQIF_V2";
    public string Language { get; set; } = "es";
    public string DefaultQuestionType { get; set; } = "single_choice";
}

public class AiNormalizeImportRequest
{
    public bool GenerateMissingJustifications { get; set; }
    public bool ValidateSemantics { get; set; } = true;
    public bool UseGrounding { get; set; }
}

public sealed class AiJobDto
{
    public required Guid AiJobId { get; init; }
    public required string Status { get; init; }
    public required string JobType { get; init; }
    public string? Stage { get; init; }
    public int? ProgressPercent { get; init; }
    public string? ErrorMessage { get; init; }
    public string? ErrorCode { get; init; }
    public DateTime? NextRetryAt { get; init; }
    public int RetryAttempt { get; init; }
    public int? CreditsConsumed { get; init; }
    public CqifDocument? Result { get; init; }
    public Guid? QuestionImportBatchId { get; init; }
    public Guid? TargetQuizId { get; init; }
    public Guid? StudyMaterialId { get; init; }
    public string? StudyMaterialTitle { get; init; }
    public int? PageFrom { get; init; }
    public int? PageTo { get; init; }
    public int? QuestionCount { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? StartedAt { get; init; }
    public DateTime? CompletedAt { get; init; }
}

public sealed class ClearAiInboxHistoryResultDto
{
    public required int RemovedCount { get; init; }
}

public sealed class AiJobSummaryDto
{
    public required Guid AiJobId { get; init; }
    public required string Status { get; init; }
    public required string JobType { get; init; }
    public string? Stage { get; init; }
    public int? ProgressPercent { get; init; }
    public string? ErrorCode { get; init; }
    public Guid? StudyMaterialId { get; init; }
    public string? StudyMaterialTitle { get; init; }
    public Guid? TargetQuizId { get; init; }
    public Guid? QuestionImportBatchId { get; init; }
    public bool ImportReadyForReview { get; init; }
    public int? PageFrom { get; init; }
    public int? PageTo { get; init; }
    public int? QuestionCount { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? CompletedAt { get; init; }
}

public sealed class AiNormalizeRawTextResponse
{
    public required CqifDocument Document { get; init; }
    public required Guid AiJobId { get; init; }
    public required int CreditsConsumed { get; init; }
}
