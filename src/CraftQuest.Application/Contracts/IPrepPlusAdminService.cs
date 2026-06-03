using CraftQuest.Application.Models.PrepPlus;

namespace CraftQuest.Application.Contracts;

public interface IPrepPlusAdminService
{
    Task<IReadOnlyList<PrepCategoryDto>> GetCategoryTreeAsync(
        bool includeInactive = false,
        CancellationToken cancellationToken = default);

    Task<PrepCategoryDto> CreateCategoryAsync(
        UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCategoryDto> UpdateCategoryAsync(
        Guid categoryId,
        UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteCategoryAsync(Guid categoryId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PrepLinkableQuizDto>> ListLinkableQuizzesAsync(
        string? search = null,
        int take = 100,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PrepCatalogItemSummaryDto>> ListCatalogItemsAsync(
        Guid? categoryId,
        bool? isPublished,
        bool includeDeleted,
        string? search,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> GetCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> CreateCatalogItemAsync(
        Guid adminUserId,
        CreatePrepCatalogItemRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> UpdateCatalogItemAsync(
        Guid catalogItemId,
        UpdatePrepCatalogItemRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> UpsertOffersAsync(
        Guid catalogItemId,
        UpsertPrepAccessOffersRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> UpsertSampleQuestionsAsync(
        Guid catalogItemId,
        UpsertPrepSampleQuestionsRequest request,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> PublishCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemDetailDto> UnpublishCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task DeleteCatalogItemAsync(Guid catalogItemId, CancellationToken cancellationToken = default);
}
