using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Practice;

internal static class PracticeSessionCleanup
{
    public static async Task DeleteSessionsForQuizAsync(
        CraftQuestDbContext dbContext,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var sessionIds = await dbContext.PracticeSessions
            .Where(s => s.QuizId == quizId)
            .Select(s => s.PracticeSessionId)
            .ToListAsync(cancellationToken);

        await DeleteSessionsByIdAsync(dbContext, sessionIds, cancellationToken);
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

        await DeleteSessionsByIdAsync(dbContext, sessionIds, cancellationToken);
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

        var snapshotIds = await dbContext.PracticeQuestionSnapshots
            .Where(s => sessionIds.Contains(s.PracticeSessionId))
            .Select(s => s.PracticeQuestionSnapshotId)
            .ToListAsync(cancellationToken);

        if (snapshotIds.Count > 0)
        {
            await dbContext.PracticeAnswerOptionSnapshots
                .Where(a => snapshotIds.Contains(a.PracticeQuestionSnapshotId))
                .ExecuteDeleteAsync(cancellationToken);

            await dbContext.PracticeQuestionSnapshots
                .Where(s => snapshotIds.Contains(s.PracticeQuestionSnapshotId))
                .ExecuteDeleteAsync(cancellationToken);
        }

        await dbContext.PracticeSessions
            .Where(s => sessionIds.Contains(s.PracticeSessionId))
            .ExecuteDeleteAsync(cancellationToken);
    }
}
