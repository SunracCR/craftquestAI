using System.Text;
using System.Text.RegularExpressions;

namespace CraftQuest.Infrastructure.Services.Ai;

public static partial class StudyMaterialTextChunker
{
    private static readonly Regex PageMarkerRegex = PageMarkerRegexFactory();

    public static IReadOnlyList<string> SplitIntoChunks(string sourceText, int targetWordsPerChunk)
    {
        var normalized = sourceText.Trim();
        if (string.IsNullOrEmpty(normalized))
        {
            return [string.Empty];
        }

        if (CountWords(normalized) <= targetWordsPerChunk)
        {
            return [normalized];
        }

        var sections = ExtractSections(normalized);
        return PackSectionsIntoChunks(sections, targetWordsPerChunk)
            .Select(sb => sb.ToString().Trim())
            .Where(c => c.Length > 0)
            .ToList();
    }

    public static int[] DistributeQuestionCounts(int totalQuestions, int chunkCount)
    {
        if (chunkCount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(chunkCount));
        }

        if (totalQuestions <= 0)
        {
            return Enumerable.Repeat(0, chunkCount).ToArray();
        }

        var baseCount = totalQuestions / chunkCount;
        var remainder = totalQuestions % chunkCount;
        var counts = Enumerable.Repeat(baseCount, chunkCount).ToArray();
        counts[^1] += remainder;
        return counts;
    }

    private static List<string> ExtractSections(string sourceText)
    {
        if (!PageMarkerRegex.IsMatch(sourceText))
        {
            return SplitByParagraphs(sourceText);
        }

        var sections = new List<string>();
        var matches = PageMarkerRegex.Matches(sourceText);
        for (var i = 0; i < matches.Count; i++)
        {
            var start = matches[i].Index;
            var end = i + 1 < matches.Count ? matches[i + 1].Index : sourceText.Length;
            var block = sourceText[start..end].Trim();
            if (block.Length > 0)
            {
                sections.Add(block);
            }
        }

        if (sections.Count == 0)
        {
            return SplitByParagraphs(sourceText);
        }

        var preamble = sourceText[..matches[0].Index].Trim();
        if (preamble.Length > 0)
        {
            sections.Insert(0, preamble);
        }

        return sections;
    }

    private static List<string> SplitByParagraphs(string sourceText)
    {
        return sourceText
            .Split(["\n\n", "\r\n\r\n"], StringSplitOptions.RemoveEmptyEntries)
            .Select(p => p.Trim())
            .Where(p => p.Length > 0)
            .ToList();
    }

    private static List<StringBuilder> PackSectionsIntoChunks(IReadOnlyList<string> sections, int targetWordsPerChunk)
    {
        var chunks = new List<StringBuilder>();
        var current = new StringBuilder();
        var currentWords = 0;

        void Flush()
        {
            if (current.Length == 0)
            {
                return;
            }

            chunks.Add(current);
            current = new StringBuilder();
            currentWords = 0;
        }

        foreach (var section in sections)
        {
            var sectionWords = CountWords(section);
            if (sectionWords == 0)
            {
                continue;
            }

            if (currentWords > 0 && currentWords + sectionWords > targetWordsPerChunk)
            {
                Flush();
            }

            if (sectionWords > targetWordsPerChunk && currentWords == 0)
            {
                foreach (var sentenceChunk in SplitOversizedSection(section, targetWordsPerChunk))
                {
                    chunks.Add(new StringBuilder(sentenceChunk));
                }

                continue;
            }

            if (current.Length > 0)
            {
                current.Append("\n\n");
            }

            current.Append(section);
            currentWords += sectionWords;
        }

        Flush();

        return chunks;
    }

    private static IEnumerable<string> SplitOversizedSection(string section, int targetWordsPerChunk)
    {
        var sentences = section.Split(['.', '!', '?', '\n'], StringSplitOptions.RemoveEmptyEntries);
        var chunk = new StringBuilder();
        var words = 0;

        foreach (var raw in sentences)
        {
            var sentence = raw.Trim();
            if (sentence.Length == 0)
            {
                continue;
            }

            var sentenceWords = CountWords(sentence);
            if (words > 0 && words + sentenceWords > targetWordsPerChunk)
            {
                yield return chunk.ToString().Trim();
                chunk.Clear();
                words = 0;
            }

            if (chunk.Length > 0)
            {
                chunk.Append(' ');
            }

            chunk.Append(sentence).Append('.');
            words += sentenceWords;
        }

        if (chunk.Length > 0)
        {
            yield return chunk.ToString().Trim();
        }
    }

    private static int CountWords(string text) =>
        string.IsNullOrWhiteSpace(text)
            ? 0
            : text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;

    [GeneratedRegex(@"---\s*Page\s+\d+\s*---", RegexOptions.IgnoreCase)]
    private static partial Regex PageMarkerRegexFactory();
}
