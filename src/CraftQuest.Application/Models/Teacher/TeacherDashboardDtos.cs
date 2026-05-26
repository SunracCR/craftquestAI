namespace CraftQuest.Application.Models.Teacher;

public sealed class TeacherDashboardDto
{
    public required int TotalStudents { get; init; }
    public required int ActiveClasses { get; init; }
    public required int PublishedQuizzes { get; init; }
    public required int SessionsThisWeek { get; init; }
    public required int UniqueActiveStudentsThisWeek { get; init; }
    public required IReadOnlyList<ActivityFeedItemDto> RecentActivity { get; init; }
    public required IReadOnlyList<TeacherInsightDto> Insights { get; init; }
    public required IReadOnlyList<UrgentAssignmentDto> UrgentAssignments { get; init; }
}

public sealed class ActivityFeedItemDto
{
    public required Guid PracticeSessionId { get; init; }
    public required string StudentName { get; init; }
    public string? StudentAvatarId { get; init; }
    public required string QuizTitle { get; init; }
    public required string? AssignmentTitle { get; init; }
    public required int ScorePercent { get; init; }
    public required bool Passed { get; init; }
    public required DateTime CompletedAt { get; init; }
}

public sealed class TeacherInsightDto
{
    /// <summary>high_error_rate | most_active_sessions | warning | positive</summary>
    public required string Type { get; init; }
    public string? Message { get; init; }
    public IReadOnlyDictionary<string, string>? Params { get; init; }
    public Guid? QuizId { get; init; }
    public Guid? AssignmentId { get; init; }
    public string? QuizTitle { get; init; }
}

public sealed class UrgentAssignmentDto
{
    public required Guid AssignmentId { get; init; }
    public required Guid ClassId { get; init; }
    public required string Title { get; init; }
    public required string ClassName { get; init; }
    public required DateTime? DueAt { get; init; }
    public required int PendingStudents { get; init; }
    public required int TotalMembers { get; init; }
    public required int UniqueStudentsCompleted { get; init; }
}

public sealed class ClassAnalyticsDto
{
    public required Guid ClassId { get; init; }
    public required string ClassName { get; init; }
    public required int TotalMembers { get; init; }
    public required int TotalSessions { get; init; }
    public required decimal AverageScore { get; init; }
    public required IReadOnlyList<AssignmentAnalyticsSummaryDto> Assignments { get; init; }
}

public sealed class AssignmentAnalyticsSummaryDto
{
    public required Guid AssignmentId { get; init; }
    public required string Title { get; init; }
    /// <summary>Distinct students with at least one finished session.</summary>
    public required int CompletedCount { get; init; }
    public required int TotalMembers { get; init; }
    public required decimal AverageScore { get; init; }
}
