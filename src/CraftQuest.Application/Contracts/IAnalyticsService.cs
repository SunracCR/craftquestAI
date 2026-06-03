using CraftQuest.Application.Models.Analytics;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Contracts;

public interface IAnalyticsService
{
    Task RecordFinishedPracticeSessionAsync(
        PracticeSession session,
        CancellationToken cancellationToken = default);

    Task<QuizAnalyticsDto> GetQuizAnalyticsAsync(
        Guid teacherUserId,
        Guid quizId,
        Guid? classId = null,
        Guid? assignmentId = null,
        CancellationToken cancellationToken = default);
}
