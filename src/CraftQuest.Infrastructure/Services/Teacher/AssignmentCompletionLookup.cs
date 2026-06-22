using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Teacher;

internal static class AssignmentCompletionLookup
{
    public static async Task<IReadOnlyDictionary<Guid, int>> LoadUniqueCompletedCountsAsync(
        CraftQuestDbContext dbContext,
        IEnumerable<Guid> assignmentIds,
        CancellationToken cancellationToken = default)
    {
        var ids = assignmentIds.Distinct().ToList();
        if (ids.Count == 0)
        {
            return new Dictionary<Guid, int>();
        }

        return await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId.HasValue
                && ids.Contains(ps.AssignmentId.Value)
                && ps.Status == "finished"
                && ps.StudentUserId != null)
            .GroupBy(ps => ps.AssignmentId!.Value)
            .Select(g => new
            {
                AssignmentId = g.Key,
                Students = g.Select(ps => ps.StudentUserId!.Value).Distinct().Count(),
            })
            .ToDictionaryAsync(x => x.AssignmentId, x => x.Students, cancellationToken);
    }
}
