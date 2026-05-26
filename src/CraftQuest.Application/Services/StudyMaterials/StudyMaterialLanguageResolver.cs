using System.Text.RegularExpressions;
using CraftQuest.Application.Services.Imports;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services.StudyMaterials;

/// <summary>Detects and resolves quiz generation language from study material text (not UI locale).</summary>
public static class StudyMaterialLanguageResolver
{
    private static readonly string[] EnglishMarkers =
    [
        "the", "and", "of", "to", "in", "is", "that", "for", "with", "this", "are", "was", "be",
        "on", "as", "by", "from", "or", "an", "at", "which", "can", "not", "have", "has", "will",
        "experiment", "software", "engineering", "chapter", "section", "study", "data", "method",
    ];

    private static readonly string[] SpanishMarkers =
    [
        "el", "la", "de", "que", "y", "en", "un", "una", "los", "las", "del", "al", "por", "con",
        "para", "como", "es", "son", "se", "su", "sus", "este", "esta", "estos", "estas", "más",
        "pregunta", "capítulo", "sección", "estudio", "método", "datos", "ingeniería",
    ];

    private static readonly string[] PortugueseMarkers =
    [
        "o", "a", "de", "que", "e", "em", "um", "uma", "os", "as", "do", "da", "dos", "das", "por",
        "com", "para", "como", "é", "são", "se", "seu", "sua", "este", "esta", "não", "mais",
        "pergunta", "capítulo", "secção", "estudo", "método", "dados", "engenharia",
    ];

    public static string DetectFromText(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return "en";
        }

        var sample = text.Length > 12_000 ? text[..12_000] : text;
        var lower = sample.ToLowerInvariant();

        var scores = new Dictionary<string, int>(StringComparer.Ordinal)
        {
            ["en"] = ScoreMarkers(lower, EnglishMarkers),
            ["es"] = ScoreMarkers(lower, SpanishMarkers),
            ["pt"] = ScoreMarkers(lower, PortugueseMarkers),
        };

        var best = scores.MaxBy(kv => kv.Value);
        if (best.Value < 4)
        {
            return "en";
        }

        var top = scores.Where(kv => kv.Value >= best.Value - 2).Select(kv => kv.Key).ToList();
        if (top.Count > 1 && top.Contains("en"))
        {
            return "en";
        }

        return CqifExcelTemplateTexts.NormalizeLanguage(best.Key);
    }

    public static string Resolve(StudyMaterial material, int pageFrom, int pageTo)
    {
        if (!string.IsNullOrWhiteSpace(material.LanguageCode))
        {
            return CqifExcelTemplateTexts.NormalizeLanguage(material.LanguageCode);
        }

        var scopeText = BuildDetectionSample(material, pageFrom, pageTo);
        return CqifExcelTemplateTexts.NormalizeLanguage(DetectFromText(scopeText));
    }

    internal static string BuildDetectionSample(StudyMaterial material, int pageFrom, int pageTo)
    {
        if (!string.IsNullOrWhiteSpace(material.EditedExtractedText))
        {
            return material.EditedExtractedText;
        }

        if (!string.IsNullOrWhiteSpace(material.OriginalText))
        {
            return material.OriginalText;
        }

        return string.Join(
            "\n",
            material.Pages
                .Where(p => p.PageNumber >= pageFrom && p.PageNumber <= pageTo)
                .OrderBy(p => p.PageNumber)
                .Select(p => p.ExtractedText ?? string.Empty));
    }

    private static int ScoreMarkers(string lower, IEnumerable<string> markers)
    {
        var score = 0;
        foreach (var marker in markers)
        {
            if (WordPattern(marker).IsMatch(lower))
            {
                score++;
            }
        }

        return score;
    }

    private static Regex WordPattern(string word) =>
        new($@"\b{Regex.Escape(word)}\b", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
}
