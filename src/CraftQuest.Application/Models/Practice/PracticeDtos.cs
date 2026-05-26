using CraftQuest.Application.Models.Analytics;

namespace CraftQuest.Application.Models.Practice;

public class StartPracticeSessionRequest
{
    public Guid QuizId { get; set; }
    public Guid? ClassId { get; set; }
    public Guid? AssignmentId { get; set; }
    public string Mode { get; set; } = "practice";

    /// <summary>
    /// When set, overrides the quiz's <c>RandomizeQuestions</c> setting for this session.
    /// </summary>
    public bool? RandomizeQuestions { get; set; }

    /// <summary>
    /// When true, elapsed time is tracked and shown in results and teacher review.
    /// </summary>
    public bool ShowElapsedTimer { get; set; }

    /// <summary>Client timezone offset in minutes (same as Dart DateTime.timeZoneOffset).</summary>
    public int? ClientUtcOffsetMinutes { get; set; }
}

public sealed class PracticeSessionDto
{
    public required Guid PracticeSessionId { get; init; }
    public required Guid QuizId { get; init; }
    public required string Status { get; init; }
    public required DateTime StartedAt { get; init; }
    public bool ShowElapsedTimer { get; init; }
    public int CurrentQuestionIndex { get; init; }
    public int ElapsedSecondsBeforePause { get; init; }
    public int AnsweredCount { get; init; }
    public int TotalQuestions { get; init; }
    public required IReadOnlyList<PracticeQuestionDto> Questions { get; init; }
}

public sealed class PracticeActiveSessionSummaryDto
{
    public required Guid PracticeSessionId { get; init; }
    public required Guid QuizId { get; init; }
    public required DateTime StartedAt { get; init; }
    public DateTime? PausedAt { get; init; }
    public required DateTime LastActivityAt { get; init; }
    public int CurrentQuestionIndex { get; init; }
    public int AnsweredCount { get; init; }
    public int TotalQuestions { get; init; }
}

public sealed class UpdatePracticeProgressRequest
{
    public int CurrentQuestionIndex { get; set; }
    public int ElapsedSecondsBeforePause { get; set; }
}

public sealed class PracticeQuestionDto
{
    public required Guid PracticeQuestionSnapshotId { get; init; }
    public required Guid QuestionId { get; init; }
    public required int DisplayOrder { get; init; }
    public required string QuestionText { get; init; }
    public required string QuestionType { get; init; }
    public string? QuestionMediaUrl { get; init; }
    public required string AnswerStatus { get; init; }
    public IReadOnlyList<Guid> SelectedAnswerOptionIds { get; init; } = [];
    public required IReadOnlyList<PracticeAnswerOptionDto> Answers { get; init; }
}

public sealed class PracticeAnswerOptionDto
{
    public required Guid AnswerOptionId { get; init; }
    public required int DisplayOrder { get; init; }
    public required string DisplayLabel { get; init; }
    public string? Text { get; init; }
    public Guid? MediaAssetId { get; init; }
    public string? MediaUrl { get; init; }
}

public class SubmitAnswerRequest
{
    public List<Guid> SelectedAnswerOptionIds { get; set; } = [];
}

public sealed class SubmitAnswerResultDto
{
    public required Guid PracticeQuestionSnapshotId { get; init; }
    public required bool Accepted { get; init; }
    public required string AnswerStatus { get; init; }
}

public sealed class PracticeSessionResultDto
{
    public required Guid PracticeSessionId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required decimal Percentage { get; init; }
    public required int CorrectAnswers { get; init; }
    public required int IncorrectAnswers { get; init; }
    public required int OmittedAnswers { get; init; }
    /// <summary>
    /// When false, the student must not see per-question correct answers (assignment policy).
    /// </summary>
    public required bool CanViewDetailedReview { get; init; }
    /// <summary>Assignment answer policy when this session belongs to an assignment.</summary>
    public string? AssignmentShowCorrectAnswersMode { get; init; }
    public DateTime? AssignmentDueAt { get; init; }
    public decimal? ScoreTrendVsPrevious { get; init; }
    public required IReadOnlyList<PracticeWeakQuestionDto> QuestionsToReview { get; init; }
}

public sealed class PracticeWeakQuestionDto
{
    public required Guid PracticeQuestionSnapshotId { get; init; }
    public required Guid QuestionId { get; init; }
    public required string QuestionText { get; init; }
    public required int DisplayOrder { get; init; }
}

public sealed class MyPracticeAttemptSummaryDto
{
    public required Guid PracticeSessionId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required string Status { get; init; }
    public DateTime? FinishedAt { get; init; }
    public required DateTime StartedAt { get; init; }
    public int? DurationSeconds { get; init; }
    public bool ShowElapsedTimer { get; init; }
}

public sealed class MyQuizPracticeAnalyticsDto
{
    public required Guid QuizId { get; init; }
    public required int FinishedAttempts { get; init; }
    public decimal? AveragePercentage { get; init; }
    public decimal? BestPercentage { get; init; }
    public required IReadOnlyList<QuestionAnalyticsDto> Questions { get; init; }
}

public sealed class StudentAssignmentSummaryDto
{
    public required Guid AssignmentId { get; init; }
    public required string AssignmentTitle { get; init; }
    public required int FinishedAttempts { get; init; }
    public decimal? BestPercentage { get; init; }
    public decimal? LastPercentage { get; init; }
    public decimal? AveragePercentage { get; init; }
    public decimal? ScoreTrend { get; init; }
    public required IReadOnlyList<AssignmentAttemptTrendDto> AttemptTrend { get; init; }
    public required IReadOnlyList<QuestionAnalyticsDto> HardQuestionsForMe { get; init; }
    public required bool CanViewDetailedReview { get; init; }
    public required string AssignmentShowCorrectAnswersMode { get; init; }
    public DateTime? AssignmentDueAt { get; init; }
}

public sealed class AssignmentAttemptTrendDto
{
    public required int AttemptNumber { get; init; }
    public required decimal Percentage { get; init; }
    public required DateTime FinishedAt { get; init; }
    public required Guid PracticeSessionId { get; init; }
}

