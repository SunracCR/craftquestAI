namespace CraftQuest.Application.Models.PrepPlus;

public sealed class PrepReferralCodeDto
{
    public required string Code { get; init; }
    public required string ShareUrl { get; init; }
    public required string Slug { get; init; }
}

public sealed class PrepPublicPreviewDto
{
    public required Guid CatalogItemId { get; init; }
    public required string Slug { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string CategoryName { get; init; }
    public required string RootCategoryType { get; init; }
    public required int QuestionCount { get; init; }
    public required bool HasFreeOffer { get; init; }
    public decimal? LowestPaidPrice { get; init; }
    public string? CurrencyCode { get; init; }
    public int? BestOfferDurationDays { get; init; }
    public string? CoverMediaUrl { get; init; }
}

public sealed class PrepCatalogItemSlugDto
{
    public required Guid CatalogItemId { get; init; }
    public required string Slug { get; init; }
}

public sealed class PrepReferralLandingPreviewDto
{
    public required string Slug { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string CategoryName { get; init; }
    public decimal? LowestPaidPrice { get; init; }
    public string? CurrencyCode { get; init; }
    public string? CoverMediaUrl { get; init; }
}
