namespace CraftQuest.Domain.Entities;

public class QuizSection
{
    public Guid QuizSectionId { get; set; }
    public Guid QuizId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public ICollection<Question> Questions { get; set; } = [];
}
