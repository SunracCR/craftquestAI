using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.Imports;

namespace CraftQuest.Application.Services.StudyMaterials;

public static class CqifGenerationSanitizer
{
    private static readonly HashSet<string> ImageTypes =
    [
        "image_choice",
        "image_based_question",
    ];

    public static CqifDocument Sanitize(
        CqifDocument document,
        IReadOnlyList<string> allowedTypes)
    {
        var allowed = new HashSet<string>(allowedTypes, StringComparer.OrdinalIgnoreCase);
        document.Questions = document.Questions
            .Where(q => allowed.Contains(q.Type) && !ImageTypes.Contains(q.Type))
            .ToList();

        return document;
    }

    public static void ValidateOrThrow(CqifDocument document)
    {
        var issues = CqifValidator.ValidateDocument(document)
            .Where(i => i.Severity == "error")
            .ToList();

        if (document.Questions.Count == 0)
        {
            var detail = issues.Count > 0 ? issues[0].Message : "No questions remain after sanitization.";
            throw new InvalidOperationException(detail);
        }

        if (issues.Count > 0)
        {
            throw new InvalidOperationException(issues[0].Message);
        }
    }
}
