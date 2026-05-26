using CraftQuest.Application.Models.StudyMaterials;

namespace CraftQuest.Application.Services.StudyMaterials;

public static class QuizGenerationPresetApplier
{
    private static readonly HashSet<string> TextOnlyTypes =
    [
        "single_choice",
        "multiple_choice",
        "true_false",
    ];

    public static QuizGenerationParametersDto Apply(QuizGenerationParametersDto parameters)
    {
        if (string.IsNullOrWhiteSpace(parameters.Preset))
        {
            parameters.AllowedQuestionTypes = SanitizeTypes(parameters.AllowedQuestionTypes);
            return parameters;
        }

        switch (parameters.Preset.Trim().ToLowerInvariant())
        {
            case "quick_review":
                parameters.QuestionCount = Clamp(parameters.QuestionCount, 8);
                parameters.AllowedQuestionTypes = ["single_choice", "true_false"];
                parameters.Difficulty = "easy";
                parameters.PedagogicalGoal = "review";
                break;
            case "standard_exam":
                parameters.QuestionCount = Clamp(parameters.QuestionCount, 15);
                parameters.AllowedQuestionTypes =
                    ["single_choice", "multiple_choice", "true_false"];
                parameters.Difficulty = "mixed";
                parameters.PedagogicalGoal = "assessment";
                break;
            case "deep_practice":
                parameters.QuestionCount = Clamp(parameters.QuestionCount, 12);
                parameters.AllowedQuestionTypes = ["single_choice", "multiple_choice"];
                parameters.Difficulty = "hard";
                parameters.PedagogicalGoal = "review";
                break;
        }

        parameters.AllowedQuestionTypes = SanitizeTypes(parameters.AllowedQuestionTypes);
        return parameters;
    }

    private static int Clamp(int value, int fallback) => value > 0 ? value : fallback;

    private static List<string> SanitizeTypes(IEnumerable<string> types) =>
        types
            .Select(t => t.Trim().ToLowerInvariant())
            .Where(TextOnlyTypes.Contains)
            .Distinct()
            .ToList() is { Count: > 0 } list
            ? list
            : ["single_choice", "multiple_choice", "true_false"];
}
