namespace CraftQuest.Domain.Entities;

public class AnswerOptionStats
{
    public Guid AnswerOptionId { get; set; }
    public Guid QuestionId { get; set; }
    public int SelectedCount { get; set; }
    public DateTime? LastSelectedAt { get; set; }

    public QuestionAnswerOption AnswerOption { get; set; } = null!;
}
