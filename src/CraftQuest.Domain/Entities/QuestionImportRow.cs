namespace CraftQuest.Domain.Entities;

public class QuestionImportRow
{
    public Guid QuestionImportRowId { get; set; }
    public Guid QuestionImportBatchId { get; set; }
    public int RowNumber { get; set; }
    public string? RawDataJson { get; set; }
    public string? CqifQuestionJson { get; set; }
    public string Status { get; set; } = "pending";
    public Guid? CreatedQuestionId { get; set; }
    public DateTime CreatedAt { get; set; }

    public QuestionImportBatch Batch { get; set; } = null!;
    public Question? CreatedQuestion { get; set; }
}
