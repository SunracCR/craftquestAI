using CraftQuest.Application.Models.StudyMaterials;

namespace CraftQuest.Application.Contracts;

public interface IQuizGenerationService
{
    Task<QuizGenerationEstimateDto> EstimateAsync(
        Guid userId,
        Guid studyMaterialId,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default);

    Task<StartQuizGenerationResultDto> StartGenerationAsync(
        Guid userId,
        Guid studyMaterialId,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default);

    Task ProcessPendingGenerationJobsAsync(CancellationToken cancellationToken = default);

    Task<StartQuizGenerationResultDto> RetryGenerationJobAsync(
        Guid userId,
        Guid aiJobId,
        CancellationToken cancellationToken = default);
}
