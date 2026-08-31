namespace CraftQuest.Application;

public static class PlanDisplayNames
{
    public static string Localize(string? language, string? planCodeOrName)
    {
        var lang = NormalizeLanguage(language);
        var key = planCodeOrName?.Trim().ToLowerInvariant() ?? "free";

        return key switch
        {
            "free" => lang switch
            {
                "en" => "Free",
                "pt" => "Gratuito",
                _ => "Free",
            },
            "pro" => "Pro",
            "premium" => "Premium",
            "teacher" => "Tutor",
            "institution" => lang switch
            {
                "en" => "Institution",
                "pt" => "Instituicao",
                _ => "Institución",
            },
            _ => planCodeOrName?.Trim() is { Length: > 0 } name ? name : "Plan",
        };
    }

    private static string NormalizeLanguage(string? language) =>
        language?.Trim().ToLowerInvariant() switch
        {
            "en" => "en",
            "pt" => "pt",
            _ => "es",
        };
}
