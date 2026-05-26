namespace CraftQuest.Application.Models.Teacher;

public sealed class AssignmentSummaryDto
{
    public required Guid AssignmentId { get; init; }
    public required Guid ClassId { get; init; }
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public required string QuizTitle { get; init; }
    public required string Status { get; init; }
    public required string ShowCorrectAnswersMode { get; init; }
    public required DateTime? StartsAt { get; init; }
    public required DateTime? DueAt { get; init; }
    public required int? MaxAttempts { get; init; }
    public required int CompletedCount { get; init; }
    public required int TotalMembers { get; init; }
    public required DateTime CreatedAt { get; init; }
}

public sealed class AssignmentDetailDto
{
    public required Guid AssignmentId { get; init; }
    public required Guid ClassId { get; init; }
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public required string? Instructions { get; init; }
    public required string QuizTitle { get; init; }
    public required string Status { get; init; }
    public required string ShowCorrectAnswersMode { get; init; }
    public required DateTime? StartsAt { get; init; }
    public required DateTime? DueAt { get; init; }
    public required int? MaxAttempts { get; init; }
    public required int CompletedCount { get; init; }
    public required int TotalMembers { get; init; }
    public required DateTime CreatedAt { get; init; }
    public required IReadOnlyList<AssignmentAttemptDto> Attempts { get; init; }
}

public sealed class AssignmentAttemptDto
{
    public required Guid PracticeSessionId { get; init; }
    public required Guid StudentUserId { get; init; }
    public required string StudentName { get; init; }
    public string? StudentAvatarId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required int Percentage { get; init; }
    public required DateTime FinishedAt { get; init; }
}

public sealed class AssignmentCompletionDto
{
    public required int CompletedCount { get; init; }
    public required int TotalMembers { get; init; }
    public required IReadOnlyList<AssignmentMemberProgressDto> Members { get; init; }
}

public sealed class AssignmentMemberProgressDto
{
    public required Guid UserId { get; init; }
    public required string DisplayName { get; init; }
    public string? AvatarId { get; init; }
    public required bool HasCompleted { get; init; }
    public required int? BestScorePercent { get; init; }
    public required int AttemptCount { get; init; }
}

public sealed class CreateAssignmentRequest
{
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public string? Instructions { get; init; }
    public DateTime? StartsAt { get; init; }
    public DateTime? DueAt { get; init; }
    public int? MaxAttempts { get; init; }

    /// <summary>never | after_attempt | after_due_date | teacher_only</summary>
    public string ShowCorrectAnswersMode { get; init; } = "after_due_date";
}

public sealed class UpdateAssignmentRequest
{
    public required string Title { get; init; }
    public string? Instructions { get; init; }
    public DateTime? StartsAt { get; init; }
    public DateTime? DueAt { get; init; }
    public int? MaxAttempts { get; init; }

    /// <summary>never | after_attempt | after_due_date | teacher_only</summary>
    public string ShowCorrectAnswersMode { get; init; } = "after_due_date";
}

public sealed class AssignmentAnalyticsDto
{
    public required Guid AssignmentId { get; init; }
    public required Guid ClassId { get; init; }
    public required string Title { get; init; }
    public required string ClassName { get; init; }
    public required int TotalMembers { get; init; }
    public required int UniqueStudentsCompleted { get; init; }
    public required decimal CompletionRate { get; init; }
    public required decimal AverageScore { get; init; }
    public required decimal? MedianScore { get; init; }
    public required int TotalSessions { get; init; }
    public required IReadOnlyList<AssignmentStudentProgressDto> Students { get; init; }
    public required IReadOnlyList<AssignmentQuestionDifficultyDto> HardQuestions { get; init; }
    public required IReadOnlyList<ScoreDistributionBucketDto> ScoreDistribution { get; init; }
}

public sealed class AssignmentStudentProgressDto
{
    public required Guid UserId { get; init; }
    public required string DisplayName { get; init; }
    public string? AvatarId { get; init; }
    public required bool HasCompleted { get; init; }
    public required int AttemptCount { get; init; }
    public required decimal? BestScore { get; init; }
    public required decimal? LastScore { get; init; }
    public required decimal? ScoreTrend { get; init; }
    public required DateTime? LastAttemptAt { get; init; }
    public Guid? LastPracticeSessionId { get; init; }
}

public sealed class AssignmentQuestionDifficultyDto
{
    public required Guid QuestionId { get; init; }
    public required string QuestionText { get; init; }
    public required int DisplayOrder { get; init; }
    public required int AttemptsCount { get; init; }
    public required decimal ErrorRate { get; init; }
}

public sealed class ScoreDistributionBucketDto
{
    public required int MinPercent { get; init; }
    public required int MaxPercent { get; init; }
    public required int StudentCount { get; init; }
}
