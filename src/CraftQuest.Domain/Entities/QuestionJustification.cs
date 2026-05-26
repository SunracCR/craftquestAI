namespace CraftQuest.Domain.Entities;

public class QuestionJustification
{
    public Guid QuestionJustificationId { get; set; }
    public Guid QuestionId { get; set; }
    public string? JustificationText { get; set; }
    public string Status { get; set; } = "approved";
    public bool GeneratedByAi { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public Question Question { get; set; } = null!;
}
