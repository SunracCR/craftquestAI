namespace CraftQuest.Domain.Entities;

public class QuestionCorrectAnswerOption
{
    public Guid QuestionId { get; set; }
    public Guid AnswerOptionId { get; set; }
    public DateTime CreatedAt { get; set; }

    public Question Question { get; set; } = null!;
    public QuestionAnswerOption AnswerOption { get; set; } = null!;
}
