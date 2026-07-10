namespace CraftQuest.Application.Options;

public class AiOptions
{
    public const string SectionName = "Ai";

    public bool Enabled { get; set; } = true;
    public bool UseGemini { get; set; }
    public string? GeminiApiKey { get; set; }
    public string GeminiModel { get; set; } = "gemini-2.5-flash";
    public string[] GeminiFallbackModels { get; set; } = ["gemini-2.5-flash-lite"];
    public string PromptVersion { get; set; } = "cqif-v2-2026-05";
    public int CreditsPerNormalize { get; set; } = 1;
    public int CreditsPerQuizGenerationBase { get; set; } = 2;
    public int CreditsPerQuizGenerationPer10Questions { get; set; } = 1;
    /// <summary>Pages above this threshold add the medium-document surcharge.</summary>
    public int CreditsSurchargeMediumDocumentPages { get; set; } = 20;
    /// <summary>Pages above this threshold add the large-document surcharge.</summary>
    public int CreditsSurchargeLargeDocumentPages { get; set; } = 60;
    public int CreditsSurchargeMediumDocument { get; set; } = 1;
    public int CreditsSurchargeLargeDocument { get; set; } = 2;
    public string QuizGenerationPromptVersion { get; set; } = "quiz-gen-v1-2026-05";
    /// <summary>Allows full documents up to MaxPagesPerMaterial before chunking.</summary>
    public int MaxInputCharacters { get; set; } = 600_000;

    public static int CalculateDocumentSizeSurcharge(int pageCount, AiOptions options)
    {
        if (pageCount > options.CreditsSurchargeLargeDocumentPages)
        {
            return options.CreditsSurchargeLargeDocument;
        }

        if (pageCount > options.CreditsSurchargeMediumDocumentPages)
        {
            return options.CreditsSurchargeMediumDocument;
        }

        return 0;
    }

    public static int CalculateGenerationCredits(int questionCount, int pageCount, AiOptions options) =>
        options.CreditsPerQuizGenerationBase
        + (int)Math.Ceiling(questionCount / 10.0) * options.CreditsPerQuizGenerationPer10Questions
        + CalculateDocumentSizeSurcharge(pageCount, options);
}
