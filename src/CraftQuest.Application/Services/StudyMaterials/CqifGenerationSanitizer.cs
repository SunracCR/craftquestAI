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
}
