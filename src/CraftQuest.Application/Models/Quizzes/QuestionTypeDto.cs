namespace CraftQuest.Application.Models.Quizzes;

public sealed class QuestionTypeDto
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public bool SupportsMultipleCorrectAnswers { get; init; }
    public bool SupportsImages { get; init; }
    public bool RequiresOptions { get; init; }
}
