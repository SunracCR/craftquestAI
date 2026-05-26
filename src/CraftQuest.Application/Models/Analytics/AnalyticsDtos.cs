namespace CraftQuest.Application.Models.Analytics;

public sealed class QuizAnalyticsDto
{
    public required Guid QuizId { get; init; }
    public required int TotalPracticeSessions { get; init; }
    public required IReadOnlyList<QuestionAnalyticsDto> Questions { get; init; }
}

public sealed class QuestionAnalyticsDto
{
    public required Guid QuestionId { get; init; }
    public required string QuestionText { get; init; }
    public required int AttemptsCount { get; init; }
    public required int CorrectCount { get; init; }
    public required int IncorrectCount { get; init; }
    public required int OmittedCount { get; init; }
    public required IReadOnlyList<AnswerOptionAnalyticsDto> AnswerOptions { get; init; }
}

public sealed class AnswerOptionAnalyticsDto
{
    public required Guid AnswerOptionId { get; init; }
    public required string StableKey { get; init; }
    public string? Text { get; init; }
    public required bool IsCorrect { get; init; }
    public required int SelectedCount { get; init; }
    public required decimal SelectionRate { get; init; }
}
