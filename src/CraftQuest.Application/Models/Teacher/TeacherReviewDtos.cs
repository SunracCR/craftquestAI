using CraftQuest.Application.Models.Quizzes;

namespace CraftQuest.Application.Models.Teacher;

public sealed class TeacherAttemptSummaryDto
{
    public required Guid PracticeSessionId { get; init; }
    public required Guid StudentUserId { get; init; }
    public string? StudentDisplayName { get; init; }
    public string? StudentAvatarId { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public required string Status { get; init; }
    public DateTime? FinishedAt { get; init; }
    public DateTime StartedAt { get; init; }
    public int? DurationSeconds { get; init; }
    public bool ShowElapsedTimer { get; init; }
}

public sealed class TeacherPracticeReviewDto
{
    public required Guid PracticeSessionId { get; init; }
    public required Guid QuizId { get; init; }
    public required string Status { get; init; }
    public required decimal ScoreObtained { get; init; }
    public required decimal ScorePossible { get; init; }
    public DateTime? FinishedAt { get; init; }
    public required TeacherStudentDto Student { get; init; }
    public required IReadOnlyList<TeacherPracticeQuestionReviewDto> Questions { get; init; }
    public bool RevealCorrectAnswers { get; init; } = true;
}

public sealed class TeacherStudentDto
{
    public required Guid UserId { get; init; }
    public string? DisplayName { get; init; }
}

public sealed class TeacherPracticeQuestionReviewDto
{
    public required Guid PracticeQuestionSnapshotId { get; init; }
    public required Guid QuestionId { get; init; }
    public required int DisplayOrder { get; init; }
    public required string QuestionText { get; init; }
    public string? QuestionMediaUrl { get; init; }
    public bool? IsCorrect { get; init; }
    public required decimal PointsAwarded { get; init; }
    public required decimal PointsPossible { get; init; }
    public required string AnswerStatus { get; init; }
    public required IReadOnlyList<TeacherAnswerOptionReviewDto> AnswersAsDisplayedToStudent { get; init; }
    public string? JustificationText { get; init; }
    public IReadOnlyList<QuestionJustificationSourceReviewDto> JustificationSources { get; init; } = [];
}

public sealed class TeacherAnswerOptionReviewDto
{
    public required Guid AnswerOptionId { get; init; }
    public string? StableKey { get; init; }
    public required int DisplayOrder { get; init; }
    public required string DisplayLabel { get; init; }
    public string? Text { get; init; }
    public string? MediaUrl { get; init; }
    public required bool WasSelected { get; init; }
    public required bool IsCorrect { get; init; }
}
