using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Models.Guest;

public class GuestEnterRequest
{
    public string Code { get; set; } = string.Empty;
}

public sealed class GuestVisitDto
{
    public required Guid GuestVisitId { get; init; }
    public required string Token { get; init; }
    public required Guid QuizId { get; init; }
    public required string QuizTitle { get; init; }
    public string? QuizDescription { get; init; }
    public required int QuestionCount { get; init; }
    public required DateTime ExpiresAt { get; init; }
}

public sealed class GuestStartPracticeRequest
{
    public bool? RandomizeQuestions { get; set; }
    public bool ShowElapsedTimer { get; set; }
}

public sealed class GuestAttemptSummaryDto
{
    public required Guid PracticeSessionId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required string Status { get; init; }
    public required DateTime StartedAt { get; init; }
    public DateTime? FinishedAt { get; init; }
    public int? DurationSeconds { get; init; }
    public bool ShowElapsedTimer { get; init; }
}

// Reuse PracticeSessionDto, SubmitAnswerRequest, SubmitAnswerResultDto,
// PracticeSessionResultDto, UpdatePracticeProgressRequest, TeacherPracticeReviewDto
// from their respective namespaces.
