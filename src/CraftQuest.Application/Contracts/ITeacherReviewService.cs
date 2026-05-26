using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface ITeacherReviewService
{
    Task<IReadOnlyList<TeacherAttemptSummaryDto>> ListQuizAttemptsAsync(
        Guid teacherUserId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<TeacherPracticeReviewDto> GetPracticeSessionReviewAsync(
        Guid teacherUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default);
}
