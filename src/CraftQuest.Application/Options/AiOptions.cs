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
    public string QuizGenerationPromptVersion { get; set; } = "quiz-gen-v1-2026-05";
    public int MaxInputCharacters { get; set; } = 120_000;

    public static int CalculateGenerationCredits(int questionCount, AiOptions options) =>
        options.CreditsPerQuizGenerationBase
        + (int)Math.Ceiling(questionCount / 10.0) * options.CreditsPerQuizGenerationPer10Questions;
}
