namespace CraftQuest.Application.Models.Quizzes;

public sealed class AnswerOptionDto
{
    public required Guid AnswerOptionId { get; init; }
    public required string StableKey { get; init; }
    public string? Text { get; init; }
    public Guid? MediaAssetId { get; init; }
}
