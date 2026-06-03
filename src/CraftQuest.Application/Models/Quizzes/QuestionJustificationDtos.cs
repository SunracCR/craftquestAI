namespace CraftQuest.Application.Models.Quizzes;

public sealed class QuestionJustificationDto
{
    public string? Text { get; init; }
    public string Status { get; init; } = "approved";
    public bool GeneratedByAi { get; init; }
    public string Visibility { get; init; } = "never";
    public IReadOnlyList<QuestionJustificationSourceDto> Sources { get; init; } = [];
}

public sealed class QuestionJustificationSourceDto
{
    public Guid JustificationSourceId { get; init; }
    public string? Title { get; init; }
    public required string SourceUrl { get; init; }
    public string? Provider { get; init; }
    public string? Snippet { get; init; }
    public int? PageNumber { get; init; }
    public Guid? StudyMaterialId { get; init; }
    public bool IsPrimary { get; init; }
}

/// <summary>Serialized in practice snapshots and returned in attempt review.</summary>
public sealed class QuestionJustificationSourceReviewDto
{
    public string? Title { get; init; }
    public string? SourceUrl { get; init; }
    public string? Snippet { get; init; }
    public int? PageNumber { get; init; }
    public bool IsPrimary { get; init; }
}
