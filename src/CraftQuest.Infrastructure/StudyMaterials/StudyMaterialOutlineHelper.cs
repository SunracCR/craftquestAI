using CraftQuest.Application.Contracts;

namespace CraftQuest.Infrastructure.StudyMaterials;

public static class StudyMaterialOutlineHelper
{
    public static List<ExtractedSection> BuildHeuristicSections(IReadOnlyList<ExtractedPage> pages)
    {
        var sections = new List<ExtractedSection>();
        var sort = 0;
        foreach (var page in pages)
        {
            var firstLine = page.Text.Split('\n', StringSplitOptions.RemoveEmptyEntries)
                .Select(l => l.Trim())
                .FirstOrDefault(l => l.Length is >= 4 and <= 120);

            if (firstLine is null
                || !char.IsUpper(firstLine[0])
                || firstLine.Count(c => c == '.') > 2)
            {
                continue;
            }

            sections.Add(new ExtractedSection
            {
                Title = firstLine,
                PageFrom = page.PageNumber,
                PageTo = page.PageNumber,
                SortOrder = sort++,
            });
        }

        return sections.Take(40).ToList();
    }

    public static bool DetectNeedsOcr(IReadOnlyList<ExtractedPage> pages)
    {
        if (pages.Count == 0)
        {
            return true;
        }

        var emptyOrLow = pages.Count(p => p.ExtractionQuality is "empty" or "low");
        return emptyOrLow >= pages.Count * 0.6;
    }

    /// <summary>
    /// Hard reject only when extraction found almost no text overall (not by page ratio alone).
    /// Many PDFs have cover/figure pages that skew per-page stats while text is selectable.
    /// </summary>
    public static bool HasMeaningfulExtractableContent(
        IReadOnlyList<ExtractedPage> pages,
        int minTotalWords = 50)
    {
        if (pages.Count == 0)
        {
            return false;
        }

        var totalWords = pages.Sum(p => p.WordCount);
        if (totalWords >= minTotalWords)
        {
            return true;
        }

        var goodPages = pages.Count(p => p.ExtractionQuality == "good");
        if (goodPages >= 1 && totalWords >= 20)
        {
            return true;
        }

        var pagesWithSomeText = pages.Count(p => p.WordCount >= 4);
        return pagesWithSomeText >= Math.Max(2, pages.Count / 20) && totalWords >= 30;
    }

    public static bool ShouldRejectAsUnselectable(IReadOnlyList<ExtractedPage> pages) =>
        !HasMeaningfulExtractableContent(pages);

    public static int CountWords(string text) =>
        string.IsNullOrWhiteSpace(text)
            ? 0
            : text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;
}
