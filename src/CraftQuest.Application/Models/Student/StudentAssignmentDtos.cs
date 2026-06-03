namespace CraftQuest.Application.Models.Student;

public sealed class StudentAssignmentDto
{
    public required Guid AssignmentId { get; init; }
    public required Guid ClassId { get; init; }
    public required string ClassName { get; init; }
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public required string QuizTitle { get; init; }
    public string? Instructions { get; init; }
    public required string Status { get; init; }
    public required DateTime? StartsAt { get; init; }
    public required DateTime? DueAt { get; init; }
    public required int? MaxAttempts { get; init; }
    public required bool RandomizeQuestions { get; init; }
    public required bool AllowStudentRandomizeQuestions { get; init; }
    public required bool ForfeitExitCountsAsAttempt { get; init; }
    public required int MyAttemptCount { get; init; }
    public required string TeacherDisplayName { get; init; }
    public required DateTime CreatedAt { get; init; }
}

public sealed class StudentClassSummaryDto
{
    public required Guid ClassId { get; init; }
    public required string Name { get; init; }
    public string? Description { get; init; }
    public required string TeacherDisplayName { get; init; }
    public required int ActiveAssignmentCount { get; init; }
}

public sealed class StudentAssignmentAttemptSummaryDto
{
    public required Guid PracticeSessionId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required string Status { get; init; }
    public DateTime? FinishedAt { get; init; }
    public required DateTime StartedAt { get; init; }
    public int? DurationSeconds { get; init; }
    public bool ShowElapsedTimer { get; init; }
    public required bool CanViewDetailedReview { get; init; }
    public required string AssignmentShowCorrectAnswersMode { get; init; }
    public DateTime? AssignmentDueAt { get; init; }
}
