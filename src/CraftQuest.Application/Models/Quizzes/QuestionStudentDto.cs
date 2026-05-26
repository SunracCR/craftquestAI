namespace CraftQuest.Application.Models.Quizzes;

/// <summary>
/// Question view for students — never includes correct answer IDs.
/// </summary>
public sealed class QuestionStudentDto
{
    public required Guid QuestionId { get; init; }
    public required string QuestionType { get; init; }
    public required string Text { get; init; }
    public bool RandomizeAnswerOptions { get; init; }
    public required IReadOnlyList<AnswerOptionDto> AnswerOptions { get; init; }
}
