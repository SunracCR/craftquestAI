using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface IPracticeService
{
    Task<PracticeSessionDto> StartSessionAsync(
        Guid studentUserId,
        StartPracticeSessionRequest request,
        CancellationToken cancellationToken = default);

    Task<SubmitAnswerResultDto> SubmitAnswerAsync(
        Guid studentUserId,
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        SubmitAnswerRequest request,
        CancellationToken cancellationToken = default);

    Task<PracticeSessionResultDto> FinishSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<PracticeActiveSessionSummaryDto?> GetActiveSessionForQuizAsync(
        Guid studentUserId,
        Guid quizId,
        Guid? assignmentId = null,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PracticeActiveSessionSummaryDto>> GetInProgressSessionsAsync(
        Guid studentUserId,
        CancellationToken cancellationToken = default);

    Task<PracticeSessionDto> GetSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task UpdateProgressAsync(
        Guid studentUserId,
        Guid sessionId,
        UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken = default);

    Task AbandonSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MyPracticeAttemptSummaryDto>> ListMyQuizAttemptsAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<TeacherPracticeReviewDto> GetMySessionReviewAsync(
        Guid userId,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<MyQuizPracticeAnalyticsDto> GetMyQuizPracticeAnalyticsAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);
}
