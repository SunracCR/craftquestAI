namespace CraftQuest.Application.Models.Imports;

public class ProcessImportRequest
{
    public string SourceType { get; set; } = string.Empty;
    public string? RawText { get; set; }
    public bool UseAiNormalization { get; set; }
    public string Language { get; set; } = "es";
}

public sealed class QuestionImportStatusDto
{
    public required Guid ImportId { get; init; }
    public required string Status { get; init; }
    public required int TotalQuestionsDetected { get; init; }
    public required int ValidQuestions { get; init; }
    public required int QuestionsWithWarnings { get; init; }
    public required int QuestionsWithErrors { get; init; }
}

public sealed class QuestionImportPreviewDto
{
    public required Guid ImportId { get; init; }
    public required string Status { get; init; }
    public required int TotalQuestionsDetected { get; init; }
    public required int ValidQuestions { get; init; }
    public required int QuestionsWithWarnings { get; init; }
    public required int QuestionsWithErrors { get; init; }
    public required IReadOnlyList<CqifQuestion> Questions { get; init; }
    public required IReadOnlyList<ImportErrorDto> Errors { get; init; }
    public int? MaxQuestionsPerQuiz { get; init; }
    public int CurrentQuestionCountInQuiz { get; init; }
    public int? ImportableQuestionCount { get; init; }
    public string? PlanName { get; init; }
}

public sealed class ImportErrorDto
{
    public int? RowNumber { get; init; }
    public string? FieldName { get; init; }
    public required string ErrorCode { get; init; }
    public required string Message { get; init; }
    public required string Severity { get; init; }
}

public sealed class QuestionImportConfirmResultDto
{
    public required Guid ImportId { get; init; }
    public required int CreatedQuestions { get; init; }
    public required int SkippedQuestions { get; init; }
    public required int SkippedDueToPlanLimit { get; init; }
    public int? MaxQuestionsPerQuiz { get; init; }
    public string? PlanName { get; init; }
    public required IReadOnlyList<Guid> CreatedQuestionIds { get; init; }
}

public sealed class CqifValidationIssue
{
    public int? RowNumber { get; init; }
    public string? FieldName { get; init; }
    public required string ErrorCode { get; init; }
    public required string Message { get; init; }
    public string Severity { get; init; } = "error";
}
