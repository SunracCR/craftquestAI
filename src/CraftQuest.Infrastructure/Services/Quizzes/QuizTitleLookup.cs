using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Quizzes;

internal static class QuizTitleLookup
{
    public static async Task<IReadOnlyDictionary<Guid, string>> LoadTitlesAsync(
        CraftQuestDbContext dbContext,
        IEnumerable<Guid> quizIds,
        CancellationToken cancellationToken = default)
    {
        var ids = quizIds.Distinct().ToList();
        if (ids.Count == 0)
        {
            return new Dictionary<Guid, string>();
        }

        return await dbContext.Quizzes
            .IgnoreQueryFilters()
            .AsNoTracking()
            .Where(q => ids.Contains(q.QuizId))
            .ToDictionaryAsync(q => q.QuizId, q => q.Title, cancellationToken);
    }

    public static string Resolve(
        IReadOnlyDictionary<Guid, string> titlesByQuizId,
        Guid quizId,
        string? fallback = null) =>
        titlesByQuizId.TryGetValue(quizId, out var title) && !string.IsNullOrWhiteSpace(title)
            ? title
            : fallback ?? "Quiz";
}
