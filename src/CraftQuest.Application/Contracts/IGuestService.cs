using CraftQuest.Application.Models.Guest;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface IGuestService
{
    Task<GuestVisitDto> EnterAsync(GuestEnterRequest request, CancellationToken cancellationToken = default);

    Task<GuestVisitDto?> GetVisitAsync(string token, CancellationToken cancellationToken = default);

    Task<PracticeSessionDto> StartPracticeAsync(
        Guid guestVisitId,
        string token,
        GuestStartPracticeRequest request,
        CancellationToken cancellationToken = default);

    Task<PracticeActiveSessionSummaryDto?> GetActiveSessionAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken = default);

    Task AbandonSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<PracticeSessionDto> GetSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<SubmitAnswerResultDto> SubmitAnswerAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        SubmitAnswerRequest request,
        CancellationToken cancellationToken = default);

    Task UpdateProgressAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken = default);

    Task<PracticeSessionResultDto> FinishSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<GuestAttemptSummaryDto>> ListAttemptsAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken = default);

    Task<TeacherPracticeReviewDto> GetAttemptReviewAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default);

    Task LeaveAsync(Guid guestVisitId, string token, CancellationToken cancellationToken = default);

    Task PurgeExpiredVisitsAsync(CancellationToken cancellationToken = default);
}
