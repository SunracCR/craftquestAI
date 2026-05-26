namespace CraftQuest.Domain.Entities;

public class QuestionImportBatch
{
    public Guid QuestionImportBatchId { get; set; }
    public Guid? QuizId { get; set; }
    public Guid UploadedByUserId { get; set; }
    public string SourceType { get; set; } = string.Empty;
    public string? OriginalFileName { get; set; }
    public Guid? MediaAssetId { get; set; }
    public string Status { get; set; } = "pending";
    public bool UseAiNormalization { get; set; }
    public int TotalRows { get; set; }
    public int ValidRows { get; set; }
    public int ErrorRows { get; set; }
    public string CqifVersion { get; set; } = "2.0";
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }

    public Quiz? Quiz { get; set; }
    public ICollection<QuestionImportRow> Rows { get; set; } = [];
    public ICollection<QuestionImportError> Errors { get; set; } = [];
}
