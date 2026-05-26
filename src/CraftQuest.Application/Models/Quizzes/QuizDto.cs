namespace CraftQuest.Application.Models.Quizzes;

public sealed class QuizDto
{
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string PublicationStatus { get; init; }
    public required string Visibility { get; init; }
    public int QuestionCount { get; init; }
    /// <summary>AI-generated import batch awaiting confirmation into this quiz.</summary>
    public Guid? PendingReviewImportId { get; init; }
    public int? PendingReviewValidQuestions { get; init; }
    public bool IsOwned { get; init; } = true;
}
