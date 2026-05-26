using System.Text;
using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Infrastructure.Services.Ai;

public static class QuizGenerationQuestionMerger
{
    public static CqifDocument Merge(
        IReadOnlyList<CqifDocument> partials,
        int targetQuestionCount,
        bool deduplicateByText = true)
    {
        var merged = new CqifDocument
        {
            CqifVersion = "2.0",
            Quiz = partials.FirstOrDefault(p => p.Quiz is not null)?.Quiz ?? new CqifQuizMetadata(),
            Questions = [],
        };

        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var order = 1;

        foreach (var partial in partials)
        {
            foreach (var question in partial.Questions)
            {
                if (deduplicateByText)
                {
                    var fingerprint = BuildFingerprint(question.Text);
                    if (!seen.Add(fingerprint))
                    {
                        continue;
                    }
                }

                question.Order = order;
                if (string.IsNullOrWhiteSpace(question.ExternalId))
                {
                    question.ExternalId = $"ai-gen-{order:D3}";
                }

                merged.Questions.Add(question);
                order++;
            }
        }

        if (merged.Questions.Count > targetQuestionCount)
        {
            merged.Questions = merged.Questions.Take(targetQuestionCount).ToList();
        }

        return merged;
    }

    public static string BuildFingerprint(string text)
    {
        var normalized = string.Join(
            ' ',
            text.Trim().ToLowerInvariant().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));

        if (normalized.Length <= 160)
        {
            return normalized;
        }

        return normalized[..160];
    }

    public static IReadOnlyList<IReadOnlyList<QuizGenerationOutlineItem>> GroupOutlineByChunk(
        IReadOnlyList<QuizGenerationOutlineItem> items,
        int chunkCount)
    {
        var groups = Enumerable.Range(0, chunkCount)
            .Select(_ => new List<QuizGenerationOutlineItem>())
            .ToList();

        foreach (var item in items.OrderBy(i => i.Index))
        {
            var chunkIndex = Math.Clamp(item.ChunkIndex, 1, chunkCount) - 1;
            groups[chunkIndex].Add(item);
        }

        return groups;
    }
}
