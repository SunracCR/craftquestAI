using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Contracts;

public interface ICqifNormalizationProvider
{
    string ProviderName { get; }

    Task<CqifDocument> NormalizeAsync(
        string rawText,
        string language,
        string defaultQuestionType,
        CancellationToken cancellationToken = default);
}
