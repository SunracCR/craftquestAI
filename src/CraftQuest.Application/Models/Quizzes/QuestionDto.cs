namespace CraftQuest.Application.Models.Quizzes;

public sealed class QuestionDto
{
    public required Guid QuestionId { get; init; }
    public required string QuestionType { get; init; }
    public required string Text { get; init; }
    public decimal Points { get; init; } = 1;
    public bool RandomizeAnswerOptions { get; init; }
    public required IReadOnlyList<AnswerOptionDto> AnswerOptions { get; init; }
    public required IReadOnlyList<Guid> CorrectAnswerOptionIds { get; init; }
}
