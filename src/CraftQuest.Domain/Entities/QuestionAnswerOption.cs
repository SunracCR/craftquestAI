namespace CraftQuest.Domain.Entities;

public class QuestionAnswerOption
{
    public Guid AnswerOptionId { get; set; }
    public Guid QuestionId { get; set; }
    public string StableKey { get; set; } = string.Empty;
    public string? AnswerText { get; set; }
    public Guid? MediaAssetId { get; set; }
    public int DefaultSortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public Question Question { get; set; } = null!;
}
