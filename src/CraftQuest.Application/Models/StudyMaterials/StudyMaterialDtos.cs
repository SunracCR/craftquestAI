namespace CraftQuest.Application.Models.StudyMaterials;

public sealed class StudyMaterialSummaryDto
{
    public required Guid StudyMaterialId { get; init; }
    public required string Title { get; init; }
    public required string FileType { get; init; }
    public required string ProcessingStatus { get; init; }
    public bool NeedsOcr { get; init; }
    public int? PageCount { get; init; }
    public int? WordCount { get; init; }
    public required DateTime CreatedAt { get; init; }
    public DateTime? RetentionExpiresAt { get; init; }
    public Guid? ActiveAiJobId { get; init; }
    public string? ActiveAiJobStatus { get; init; }
    public string? ActiveAiJobStage { get; init; }
    public int? ActiveAiJobProgressPercent { get; init; }
    public Guid? PendingReviewImportId { get; init; }
    public Guid? PendingReviewAiJobId { get; init; }
}

public sealed class StudyMaterialPageDto
{
    public required int PageNumber { get; init; }
    public string? PreviewText { get; init; }
    public required int WordCount { get; init; }
    public required string ExtractionQuality { get; init; }
}

public sealed class StudyMaterialSectionDto
{
    public required string Title { get; init; }
    public required int PageFrom { get; init; }
    public required int PageTo { get; init; }
}

public sealed class UpdateStudyMaterialExtractedTextRequest
{
    public string ExtractedText { get; set; } = string.Empty;
}

public sealed class StudyMaterialDetailDto
{
    public required Guid StudyMaterialId { get; init; }
    public required string Title { get; init; }
    public required string FileType { get; init; }
    public required string ProcessingStatus { get; init; }
    public bool NeedsOcr { get; init; }
    public string? ErrorMessage { get; init; }
    public int? PageCount { get; init; }
    public int? WordCount { get; init; }
    public int? SelectionPageFrom { get; init; }
    public int? SelectionPageTo { get; init; }
    public string? SelectionTopic { get; init; }
    public Guid? GeneratedQuizId { get; init; }
    public required IReadOnlyList<StudyMaterialPageDto> Pages { get; init; }
    public required IReadOnlyList<StudyMaterialSectionDto> Sections { get; init; }
    public int EstimatedMaxQuestions { get; init; }
    public bool RequiresTextReview { get; init; }
    public string? EditedExtractedText { get; init; }
    /// <summary>Detected document language (en, es, pt) for AI generation.</summary>
    public string? LanguageCode { get; init; }
}

public sealed class StudyMaterialUploadResultDto
{
    public required Guid StudyMaterialId { get; init; }
    public required string ProcessingStatus { get; init; }
}

public sealed class UpdateStudyMaterialSelectionRequest
{
    public int PageFrom { get; set; }
    public int PageTo { get; set; }
    public string? Topic { get; set; }
}
