using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Practice;

internal static class PracticeSessionExpiry
{
    public const int InProgressExpiryDays = 30;

    public static DateTime StaleCutoffUtc() =>
        DateTime.UtcNow.AddDays(-InProgressExpiryDays);

    public static async Task ExpireStaleSessionsForUserAsync(
        CraftQuestDbContext dbContext,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var cutoff = StaleCutoffUtc();
        var now = DateTime.UtcNow;
        var staleQuery = dbContext.PracticeSessions
            .Where(s =>
                s.StudentUserId == userId
                && s.Status == "in_progress"
                && (s.LastActivityAt ?? s.StartedAt) < cutoff);

        if (dbContext.Database.IsSqlServer())
        {
            await staleQuery.ExecuteUpdateAsync(
                setters => setters
                    .SetProperty(s => s.Status, "expired")
                    .SetProperty(s => s.FinishedAt, now),
                cancellationToken);
            return;
        }

        var staleSessions = await staleQuery.ToListAsync(cancellationToken);
        if (staleSessions.Count == 0)
        {
            return;
        }

        foreach (var session in staleSessions)
        {
            session.Status = "expired";
            session.FinishedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
