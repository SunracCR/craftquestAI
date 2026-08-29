using CraftQuest.Application.Models.PrepPlus;

namespace CraftQuest.Application.Contracts;

public interface IPrepPlusQuestionBankService
{
    Task<PrepQuestionBankDto> GetQuestionBankAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepQuizSectionDto> CreateSectionAsync(
        Guid catalogItemId,
        UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepQuizSectionDto> UpdateSectionAsync(
        Guid catalogItemId,
        Guid sectionId,
        UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteSectionAsync(
        Guid catalogItemId,
        Guid sectionId,
        CancellationToken cancellationToken = default);

    Task BulkTagQuestionsAsync(
        Guid catalogItemId,
        BulkTagPrepQuestionsRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> SetCustomPracticeAsync(
        Guid catalogItemId,
        SetPrepCustomPracticeRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PrepPracticeSectionPublicDto>> GetPracticeStructureAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepPracticePoolDto> GetPracticePoolAsync(
        Guid catalogItemId,
        IReadOnlyList<Guid>? sectionIds,
        string? difficulty,
        CancellationToken cancellationToken = default);
}
