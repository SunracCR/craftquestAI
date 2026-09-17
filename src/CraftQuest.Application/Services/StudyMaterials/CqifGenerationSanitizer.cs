using System.Text;
using System.Text.RegularExpressions;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.Imports;

namespace CraftQuest.Application.Services.StudyMaterials;

public static class CqifGenerationSanitizer
{
    private const string InvalidOutputMessage =
        "The AI returned a response that could not be converted to a valid quiz format. Please try again.";

    private static readonly HashSet<string> ImageTypes =
    [
        "image_choice",
        "image_based_question",
    ];

    private static readonly Regex[] JustificationLetterPatterns =
    [
        new(
            @"\b(?:la\s+|the\s+)?(?:opci[oó]n|opção|option|alternativa|choice|letra|letter)\s+[A-Da-d]\s+(?:es|is|é)\s+(?:la\s+|the\s+)?(?:correcta|correta|correct)\s+(?:porque|because|pois|since|ya que|porque)\s+",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled),
        new(
            @"\b(?:la\s+|the\s+)?(?:respuesta|resposta|answer)\s+(?:correcta|correta|correct)\s+(?:es|is|é)\s+[A-Da-d]\b\.?",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled),
        new(
            @"\b(?:primera|segunda|tercera|cuarta|first|second|third|fourth)\s+(?:opci[oó]n|opção|option|alternativa|choice)\b\.?",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled),
        new(
            @"\b(?:opci[oó]n|opção|option|alternativa|choice|letra|letter)\s+[A-Da-d]\b\.?",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled),
    ];

    private static readonly Regex WhitespaceCollapse =
        new(@"\s{2,}", RegexOptions.CultureInvariant | RegexOptions.Compiled);

    public static CqifDocument Sanitize(
        CqifDocument document,
        IReadOnlyList<string> allowedTypes)
    {
        var allowed = new HashSet<string>(allowedTypes, StringComparer.OrdinalIgnoreCase);
        document.Questions = document.Questions
            .Where(q => allowed.Contains(q.Type) && !ImageTypes.Contains(q.Type))
            .Select(NormalizeQuestion)
            .ToList();

        return document;
    }

    public static void ValidateOrThrow(CqifDocument document)
    {
        var validQuestions = new List<CqifQuestion>();

        for (var i = 0; i < document.Questions.Count; i++)
        {
            var question = document.Questions[i];
            var hasErrors = CqifValidator.ValidateQuestion(question, i + 1)
                .Any(issue => issue.Severity == "error");

            if (!hasErrors)
            {
                validQuestions.Add(question);
            }
        }

        document.Questions = validQuestions;

        if (document.Questions.Count == 0)
        {
            throw new AppException(InvalidOutputMessage, 502, "AI_GENERATION_INVALID_OUTPUT");
        }
    }

    public static CqifQuestion NormalizeQuestion(CqifQuestion question)
    {
        foreach (var option in question.AnswerOptions)
        {
            option.Text = CapitalizeFirstLetter(option.Text);
        }

        if (question.Justification?.Text is { Length: > 0 } justificationText)
        {
            question.Justification.Text = SanitizeJustificationText(justificationText);
        }

        return question;
    }

    public static string CapitalizeFirstLetter(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return text ?? string.Empty;
        }

        var span = text.AsSpan();
        var letterIndex = 0;
        while (letterIndex < span.Length && !char.IsLetter(span[letterIndex]))
        {
            letterIndex++;
        }

        if (letterIndex >= span.Length || char.IsUpper(span[letterIndex]))
        {
            return text;
        }

        if (letterIndex + 1 < span.Length
            && char.IsLetter(span[letterIndex + 1])
            && char.IsUpper(span[letterIndex + 1]))
        {
            return text;
        }

        var builder = new StringBuilder(text.Length);
        builder.Append(span[..letterIndex]);
        builder.Append(char.ToUpperInvariant(span[letterIndex]));
        builder.Append(span[(letterIndex + 1)..]);
        return builder.ToString();
    }

    public static string SanitizeJustificationText(string text)
    {
        var cleaned = text.Trim();
        foreach (var pattern in JustificationLetterPatterns)
        {
            cleaned = pattern.Replace(cleaned, " ");
        }

        cleaned = WhitespaceCollapse.Replace(cleaned, " ").Trim();

        if (cleaned.Length == 0)
        {
            return cleaned;
        }

        return CapitalizeFirstLetter(cleaned);
    }
}
