namespace CraftQuest.Domain.Entities;

public class QuestionJustificationSource
{
    public Guid JustificationSourceId { get; set; }
    public Guid QuestionJustificationId { get; set; }
    public string? SourceTitle { get; set; }
    public string SourceUrl { get; set; } = string.Empty;
    public string? SourceProvider { get; set; }
    public string? Snippet { get; set; }
    public int? SourcePageNumber { get; set; }
    public Guid? StudyMaterialId { get; set; }
    public DateTime RetrievedAt { get; set; }
    public bool IsPrimary { get; set; }

    public QuestionJustification Justification { get; set; } = null!;
}
