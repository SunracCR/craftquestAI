namespace CraftQuest.Infrastructure.Services.Ai;

public sealed record QuizGenerationOutlineItem(
    int Index,
    string Topic,
    string? SuggestedType,
    int ChunkIndex);

internal sealed class QuizGenerationOutlinePlan
{
    public required IReadOnlyList<QuizGenerationOutlineItem> Items { get; init; }
}
