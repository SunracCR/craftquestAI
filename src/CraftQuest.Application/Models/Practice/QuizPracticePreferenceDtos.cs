namespace CraftQuest.Application.Models.Practice;

public sealed class QuizPracticePreferenceDto
{
    public required Guid QuizId { get; init; }
    public required bool RandomizeQuestions { get; init; }
    public required bool ShowElapsedTimer { get; init; }
}

public class UpsertQuizPracticePreferenceRequest
{
    public bool RandomizeQuestions { get; set; }
    public bool ShowElapsedTimer { get; set; } = true;
}
