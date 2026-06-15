using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Practice;

internal static class PracticeSessionCleanup
{
    public static async Task DeletePracticeDataForQuizAsync(
        CraftQuestDbContext dbContext,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var sessionIds = await dbContext.PracticeSessions
            .Where(s => s.QuizId == quizId)
            .Select(s => s.PracticeSessionId)
            .ToListAsync(cancellationToken);

        var questionIds = await dbContext.Questions
            .IgnoreQueryFilters()
            .Where(q => q.QuizId == quizId)
            .Select(q => q.QuestionId)
            .ToListAsync(cancellationToken);

        var snapshotIds = await dbContext.PracticeQuestionSnapshots
            .Where(s => sessionIds.Contains(s.PracticeSessionId)
                || questionIds.Contains(s.QuestionId))
            .Select(s => s.PracticeQuestionSnapshotId)
            .ToListAsync(cancellationToken);

        await DeleteSnapshotsByIdAsync(dbContext, snapshotIds, cancellationToken);
        await DeleteSessionsByIdAsync(dbContext, sessionIds, cancellationToken);

        var guestVisitIds = await dbContext.GuestVisits
            .Where(v => v.QuizId == quizId)
            .Select(v => v.GuestVisitId)
            .ToListAsync(cancellationToken);

        foreach (var guestVisitId in guestVisitIds)
        {
            await DeleteSessionsForGuestVisitAsync(dbContext, guestVisitId, cancellationToken);
        }
    }

    public static async Task DeleteSessionsForGuestVisitAsync(
        CraftQuestDbContext dbContext,
        Guid guestVisitId,
        CancellationToken cancellationToken = default)
    {
        var sessionIds = await dbContext.PracticeSessions
            .Where(s => s.GuestVisitId == guestVisitId)
            .Select(s => s.PracticeSessionId)
            .ToListAsync(cancellationToken);

        var snapshotIds = await dbContext.PracticeQuestionSnapshots
            .Where(s => sessionIds.Contains(s.PracticeSessionId))
            .Select(s => s.PracticeQuestionSnapshotId)
            .ToListAsync(cancellationToken);

        await DeleteSnapshotsByIdAsync(dbContext, snapshotIds, cancellationToken);
        await DeleteSessionsByIdAsync(dbContext, sessionIds, cancellationToken);
    }

    private static async Task DeleteSnapshotsByIdAsync(
        CraftQuestDbContext dbContext,
        IReadOnlyList<Guid> snapshotIds,
        CancellationToken cancellationToken)
    {
        if (snapshotIds.Count == 0)
        {
            return;
        }

        if (dbContext.Database.IsRelational())
        {
            await dbContext.PracticeAnswerOptionSnapshots
                .Where(a => snapshotIds.Contains(a.PracticeQuestionSnapshotId))
                .ExecuteDeleteAsync(cancellationToken);

            await dbContext.PracticeQuestionSnapshots
                .Where(s => snapshotIds.Contains(s.PracticeQuestionSnapshotId))
                .ExecuteDeleteAsync(cancellationToken);

            return;
        }

        var answerSnapshots = await dbContext.PracticeAnswerOptionSnapshots
            .Where(a => snapshotIds.Contains(a.PracticeQuestionSnapshotId))
            .ToListAsync(cancellationToken);

        var snapshots = await dbContext.PracticeQuestionSnapshots
            .Where(s => snapshotIds.Contains(s.PracticeQuestionSnapshotId))
            .ToListAsync(cancellationToken);

        dbContext.PracticeAnswerOptionSnapshots.RemoveRange(answerSnapshots);
        dbContext.PracticeQuestionSnapshots.RemoveRange(snapshots);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task DeleteSessionsByIdAsync(
        CraftQuestDbContext dbContext,
        IReadOnlyList<Guid> sessionIds,
        CancellationToken cancellationToken)
    {
        if (sessionIds.Count == 0)
        {
            return;
        }

        if (dbContext.Database.IsRelational())
        {
            await dbContext.PracticeSessions
                .Where(s => sessionIds.Contains(s.PracticeSessionId))
                .ExecuteDeleteAsync(cancellationToken);

            return;
        }

        var sessions = await dbContext.PracticeSessions
            .Where(s => sessionIds.Contains(s.PracticeSessionId))
            .ToListAsync(cancellationToken);

        dbContext.PracticeSessions.RemoveRange(sessions);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
