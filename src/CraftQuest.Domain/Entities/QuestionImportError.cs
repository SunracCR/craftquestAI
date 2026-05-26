namespace CraftQuest.Domain.Entities;

public class QuestionImportError
{
    public Guid QuestionImportErrorId { get; set; }
    public Guid? QuestionImportRowId { get; set; }
    public Guid QuestionImportBatchId { get; set; }
    public string? FieldName { get; set; }
    public string ErrorCode { get; set; } = string.Empty;
    public string ErrorMessage { get; set; } = string.Empty;
    public string Severity { get; set; } = "error";
    public DateTime CreatedAt { get; set; }

    public QuestionImportRow? Row { get; set; }
    public QuestionImportBatch Batch { get; set; } = null!;
}
