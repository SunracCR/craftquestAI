using System.Text;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.DocumentLayoutAnalysis.TextExtractor;

namespace CraftQuest.Infrastructure.StudyMaterials;

internal static class PdfTextExtractionHelper
{
    public static string ExtractPageText(Page page)
    {
        var candidates = new List<(string Text, int Words)>();

        AddCandidate(candidates, TryGetContentOrderText(page));
        AddCandidate(candidates, page.Text?.Trim());

        if (candidates.Count == 0 || candidates.Max(c => c.Words) < 4)
        {
            AddCandidate(candidates, ExtractFromLetters(page));
        }

        return candidates
            .OrderByDescending(c => c.Words)
            .ThenByDescending(c => c.Text.Length)
            .Select(c => c.Text)
            .FirstOrDefault() ?? string.Empty;
    }

    private static void AddCandidate(List<(string Text, int Words)> candidates, string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }

        var normalized = NormalizeWhitespace(text);
        candidates.Add((normalized, StudyMaterialOutlineHelper.CountWords(normalized)));
    }

    private static string? TryGetContentOrderText(Page page)
    {
        try
        {
            return ContentOrderTextExtractor.GetText(page);
        }
        catch
        {
            return null;
        }
    }

    private static string ExtractFromLetters(Page page)
    {
        if (page.Letters.Count == 0)
        {
            return string.Empty;
        }

        var builder = new StringBuilder();
        var lastY = double.NaN;
        var lastXEnd = double.NaN;

        foreach (var letter in page.Letters
                     .OrderByDescending(l => l.StartBaseLine.Y)
                     .ThenBy(l => l.StartBaseLine.X))
        {
            var y = letter.StartBaseLine.Y;
            var x = letter.StartBaseLine.X;

            if (!double.IsNaN(lastY) && Math.Abs(y - lastY) > 2)
            {
                builder.AppendLine();
                lastXEnd = double.NaN;
            }
            else if (!double.IsNaN(lastXEnd) && x - lastXEnd > letter.Width * 0.6)
            {
                builder.Append(' ');
            }

            builder.Append(letter.Value);
            lastY = y;
            lastXEnd = letter.EndBaseLine.X;
        }

        return NormalizeWhitespace(builder.ToString());
    }

    private static string NormalizeWhitespace(string text) =>
        string.Join(
            ' ',
            text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
            .Trim();
}
