using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services.Imports;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Ai;

public class GeminiCqifNormalizationProvider(
    GeminiContentClient geminiClient,
    IOptions<AiOptions> options) : ICqifNormalizationProvider
{
    public string ProviderName => "gemini";

    public async Task<CqifDocument> NormalizeAsync(
        string rawText,
        string language,
        string defaultQuestionType,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(options.Value.GeminiApiKey))
        {
            throw new AppException("Gemini API key is not configured.", 503);
        }

        var prompt = BuildPrompt(rawText, language, defaultQuestionType);
        var result = await geminiClient.GenerateTextAsync(
            prompt,
            new { temperature = 0.2, responseMimeType = "application/json" },
            "Gemini normalization",
            cancellationToken);

        return CqifJsonParser.Parse(result.Text);
    }

    private static string BuildPrompt(string rawText, string language, string defaultQuestionType) =>
        $"""
        You are a CraftQuest CQIF v2 normalizer. Convert the input into valid CQIF JSON 2.0 only.
        Rules:
        - Output JSON only, no markdown.
        - Use answerOptions[].key stable keys (not A/B/C/D as correct answers).
        - correctAnswerKeys must reference keys from answerOptions.
        - Language for question text: {language}
        - Default question type when unclear: {defaultQuestionType}
        - cqifVersion must be "2.0"

        INPUT:
        {rawText}
        """;
}
