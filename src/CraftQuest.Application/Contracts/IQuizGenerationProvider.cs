using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.StudyMaterials;

namespace CraftQuest.Application.Contracts;

public interface IQuizGenerationProvider
{
    string ProviderName { get; }

    Task<CqifDocument> GenerateAsync(
        string sourceText,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default);
}
