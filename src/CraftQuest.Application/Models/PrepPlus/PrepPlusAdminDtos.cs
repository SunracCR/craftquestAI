namespace CraftQuest.Application.Models.PrepPlus;

public sealed class PrepLinkableQuizDto
{
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required string PublicationStatus { get; init; }
    public required int QuestionCount { get; init; }
    public required Guid CreatedByUserId { get; init; }
    public required string CreatedByDisplayName { get; init; }
}

public sealed class PrepCategoryDto
{
    public required Guid CategoryId { get; init; }
    public Guid? ParentCategoryId { get; init; }
    public required string CategoryType { get; init; }
    public required string Slug { get; init; }
    public required string Name { get; init; }
    public string? Description { get; init; }
    public string? CountryCode { get; init; }
    public string? IconKey { get; init; }
    public required int SortOrder { get; init; }
    public required bool IsActive { get; init; }
    public IReadOnlyList<PrepCategoryDto> Children { get; init; } = [];
}

public class UpsertPrepCategoryRequest
{
    public Guid? ParentCategoryId { get; set; }
    public string CategoryType { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CountryCode { get; set; }
    public string? IconKey { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public sealed class PrepCatalogItemSummaryDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public required Guid CategoryId { get; init; }
    public required string CategoryName { get; init; }
    public required string DisplayTitle { get; init; }
    public required bool IsPublished { get; init; }
    public required bool IsDeleted { get; init; }
    public DateTime? ListingEndsAt { get; init; }
    public required int QuestionCount { get; init; }
    public required int ActiveOfferCount { get; init; }
    public required int SampleQuestionCount { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
}

public sealed class PrepAccessOfferDto
{
    public required Guid OfferId { get; init; }
    public required int DurationDays { get; init; }
    public bool IsLifetimeAccess { get; init; }
    public required decimal PriceAmount { get; init; }
    public required string CurrencyCode { get; init; }
    public required bool IsFree { get; init; }
    public string? StoreProductId { get; init; }
    public required bool IsActive { get; init; }
}

public sealed class PrepSampleQuestionDto
{
    public required Guid QuestionId { get; init; }
    public required int SortOrder { get; init; }
    public required string PromptPreview { get; init; }
}

public sealed class PrepCatalogItemDetailDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public required string QuizTitle { get; init; }
    public required Guid CategoryId { get; init; }
    public required string CategoryName { get; init; }
    public required string CategoryType { get; init; }
    public string? TitleOverride { get; init; }
    public string? Description { get; init; }
    public string? Slug { get; init; }
    public string? PublicShareUrl { get; init; }
    public Guid? CoverMediaId { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
    public string? InstitutionTag { get; init; }
    public DateTime? ListingStartsAt { get; init; }
    public DateTime? ListingEndsAt { get; init; }
    public required bool IsPublished { get; init; }
    public DateTime? PublishedAt { get; init; }
    public required bool IsDeleted { get; init; }
    public required int QuestionCount { get; init; }
    public IReadOnlyList<PrepAccessOfferDto> Offers { get; init; } = [];
    public IReadOnlyList<PrepSampleQuestionDto> SampleQuestions { get; init; } = [];
}

public class CreatePrepCatalogItemRequest
{
    public Guid QuizId { get; set; }
    public Guid CategoryId { get; set; }
    public string? TitleOverride { get; set; }
    public string? Description { get; set; }
    public Guid? CoverMediaId { get; set; }
    public List<string> Tags { get; set; } = [];
    public string? InstitutionTag { get; set; }
    public DateTime? ListingStartsAt { get; set; }
    public DateTime? ListingEndsAt { get; set; }
}

public class UpdatePrepCatalogItemRequest
{
    public Guid CategoryId { get; set; }
    public string? TitleOverride { get; set; }
    public string? Description { get; set; }
    public Guid? CoverMediaId { get; set; }
    public List<string> Tags { get; set; } = [];
    public string? InstitutionTag { get; set; }
    public DateTime? ListingStartsAt { get; set; }
    public DateTime? ListingEndsAt { get; set; }
}

public class UpsertPrepAccessOfferInput
{
    public int DurationDays { get; set; }
    public bool IsLifetimeAccess { get; set; }
    public decimal PriceAmount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public bool IsFree { get; set; }
    public string? StoreProductId { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpsertPrepAccessOffersRequest
{
    public List<UpsertPrepAccessOfferInput> Offers { get; set; } = [];
}

public class UpsertPrepSampleQuestionsRequest
{
    public List<Guid> QuestionIds { get; set; } = [];
}
