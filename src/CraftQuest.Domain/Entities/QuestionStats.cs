namespace CraftQuest.Domain.Entities;

public class QuestionStats
{
    public Guid QuestionId { get; set; }
    public int AttemptsCount { get; set; }
    public int CorrectCount { get; set; }
    public int IncorrectCount { get; set; }
    public int OmittedCount { get; set; }
    public decimal? AverageTimeSeconds { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Question Question { get; set; } = null!;
}
