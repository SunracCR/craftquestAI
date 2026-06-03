using CraftQuest.Application.Models.PrepPlus;

namespace CraftQuest.Application.Contracts;

public interface IPrepPlusCatalogService
{
    Task<IReadOnlyList<PrepCategoryPublicDto>> GetPublicCategoryTreeAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PrepCatalogBrowseItemDto>> BrowseCategoryItemsAsync(
        Guid userId,
        Guid categoryId,
        string? search,
        string? priceFilter,
        string? institutionTag,
        IReadOnlyList<string>? tags,
        string? userAccessFilter,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<PrepCatalogItemPublicDetailDto> GetPublicItemAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepPreviewDto> GetPreviewAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task<PrepMyAccessesDto> GetMyAccessesAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<PrepCheckoutResultDto> CheckoutAsync(
        Guid userId,
        Guid catalogItemId,
        PrepCheckoutRequest request,
        CancellationToken cancellationToken = default);
}
