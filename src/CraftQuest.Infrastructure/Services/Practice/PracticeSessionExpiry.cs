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
        await dbContext.PracticeSessions
            .Where(s =>
                s.StudentUserId == userId
                && s.Status == "in_progress"
                && (s.LastActivityAt ?? s.StartedAt) < cutoff)
            .ExecuteUpdateAsync(
                setters => setters
                    .SetProperty(s => s.Status, "expired")
                    .SetProperty(s => s.FinishedAt, now),
                cancellationToken);
    }
}
