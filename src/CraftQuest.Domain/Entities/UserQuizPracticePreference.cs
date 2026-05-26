namespace CraftQuest.Domain.Entities;

/// <summary>
/// Per-user practice launch settings for a specific quiz (course).
/// </summary>
public class UserQuizPracticePreference
{
    public Guid UserId { get; set; }
    public Guid QuizId { get; set; }
    public bool RandomizeQuestions { get; set; }
    public bool ShowElapsedTimer { get; set; } = true;
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Quiz Quiz { get; set; } = null!;
}
