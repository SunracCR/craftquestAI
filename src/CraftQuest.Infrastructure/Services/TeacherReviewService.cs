using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services.Teacher;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class TeacherReviewService(
    CraftQuestDbContext dbContext,
    IMediaService mediaService) : ITeacherReviewService
{
    public async Task<IReadOnlyList<TeacherAttemptSummaryDto>> ListQuizAttemptsAsync(
        Guid teacherUserId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanReviewQuizAsync(teacherUserId, quizId, cancellationToken);

        return await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(s => s.QuizId == quizId && s.Status != "in_progress" && s.GuestVisitId == null)
            .OrderByDescending(s => s.FinishedAt ?? s.StartedAt)
            .Select(s => new TeacherAttemptSummaryDto
            {
                PracticeSessionId = s.PracticeSessionId,
                StudentUserId = s.StudentUserId ?? Guid.Empty,
                StudentDisplayName = s.StudentUser != null
                    ? (s.StudentUser.DisplayName ?? s.StudentUser.Email)
                    : null,
                StudentAvatarId = s.StudentUser != null ? s.StudentUser.AvatarId : null,
                ScoreObtained = s.ScoreObtained,
                ScorePossible = s.ScorePossible,
                Status = s.Status,
                FinishedAt = s.FinishedAt,
                StartedAt = s.StartedAt,
                DurationSeconds = s.DurationSeconds,
                ShowElapsedTimer = s.ShowElapsedTimer,
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<TeacherPracticeReviewDto> GetPracticeSessionReviewAsync(
        Guid teacherUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.StudentUser)
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstOrDefaultAsync(s => s.PracticeSessionId == sessionId, cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        await EnsureCanReviewQuizAsync(teacherUserId, session.QuizId, cancellationToken);

        return TeacherReviewMapper.MapReview(session, mediaService);
    }

    private async Task EnsureCanReviewQuizAsync(
        Guid teacherUserId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId && q.DeletedAt == null, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId != teacherUserId)
        {
            throw new AppException(
                "You do not have permission to review practice sessions for this quiz.",
                403);
        }
    }

}
