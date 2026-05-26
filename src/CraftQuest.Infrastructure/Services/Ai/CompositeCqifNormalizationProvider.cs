using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Ai;

public class CompositeCqifNormalizationProvider(
    IOptions<AiOptions> options,
    HeuristicCqifNormalizationProvider heuristic,
    GeminiCqifNormalizationProvider gemini) : ICqifNormalizationProvider
{
    public string ProviderName =>
        options.Value.UseGemini && !string.IsNullOrWhiteSpace(options.Value.GeminiApiKey)
            ? gemini.ProviderName
            : heuristic.ProviderName;

    public async Task<CqifDocument> NormalizeAsync(
        string rawText,
        string language,
        string defaultQuestionType,
        CancellationToken cancellationToken = default)
    {
        var aiOptions = options.Value;
        if (aiOptions.UseGemini && !string.IsNullOrWhiteSpace(aiOptions.GeminiApiKey))
        {
            try
            {
                return await gemini.NormalizeAsync(
                    rawText,
                    language,
                    defaultQuestionType,
                    cancellationToken);
            }
            catch
            {
                return await heuristic.NormalizeAsync(
                    rawText,
                    language,
                    defaultQuestionType,
                    cancellationToken);
            }
        }

        return await heuristic.NormalizeAsync(
            rawText,
            language,
            defaultQuestionType,
            cancellationToken);
    }
}
