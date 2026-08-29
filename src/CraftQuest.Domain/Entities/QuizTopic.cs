namespace CraftQuest.Domain.Entities;

public class QuizTopic
{
    public Guid QuizTopicId { get; set; }
    public Guid QuizId { get; set; }
    public Guid QuizSectionId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public QuizSection Section { get; set; } = null!;
    public ICollection<Question> Questions { get; set; } = [];
}
