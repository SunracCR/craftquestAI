using CraftQuest.Application.Models.Quizzes;

namespace CraftQuest.Application.Models.PrepPlus;

public sealed class PrepCategoryPublicDto
{
    public required Guid CategoryId { get; init; }
    public Guid? ParentCategoryId { get; init; }
    public required string CategoryType { get; init; }
    public required string Slug { get; init; }
    public required string Name { get; init; }
    public string? Description { get; init; }
    public string? CountryCode { get; init; }
    public string? IconKey { get; init; }
    public required int PublishedItemCount { get; init; }
    public IReadOnlyList<PrepCategoryPublicDto> Children { get; init; } = [];
}

public sealed class PrepCatalogBrowseItemDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public string? Slug { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required int QuestionCount { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
    public string? InstitutionTag { get; init; }
    public required bool HasFreeOffer { get; init; }
    public decimal? LowestPaidPrice { get; init; }
    public string? CurrencyCode { get; init; }
    public required string UserAccessState { get; init; }
    public DateTime? AccessExpiresAt { get; init; }
    public required bool CanPurchase { get; init; }
}

public sealed class PrepCatalogItemPublicDetailDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public string? Slug { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required Guid CategoryId { get; init; }
    public required string CategoryName { get; init; }
    public required string RootCategoryType { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
    public string? InstitutionTag { get; init; }
    public required int QuestionCount { get; init; }
    public required bool CanPurchase { get; init; }
    public DateTime? ListingEndsAt { get; init; }
    public required string UserAccessState { get; init; }
    public DateTime? AccessExpiresAt { get; init; }
    public required bool CanPractice { get; init; }
    public IReadOnlyList<PrepAccessOfferDto> Offers { get; init; } = [];
}

public sealed class PrepPreviewAnswerOptionMediaDto
{
    public required Guid AnswerOptionId { get; init; }
    public required string MediaUrl { get; init; }
}

public sealed class PrepPreviewQuestionFinishDto
{
    public required Guid QuestionId { get; init; }
    public required decimal Points { get; init; }
    public required string ScoringPolicy { get; init; }
    public required bool SupportsMultipleCorrectAnswers { get; init; }
    public required IReadOnlyList<Guid> CorrectAnswerOptionIds { get; init; }
    public string? QuestionMediaUrl { get; init; }
    public IReadOnlyList<PrepPreviewAnswerOptionMediaDto> AnswerOptionMediaUrls { get; init; } = [];
    public string? JustificationText { get; init; }
    public IReadOnlyList<QuestionJustificationSourceReviewDto> JustificationSources { get; init; } = [];
}

public sealed class PrepPreviewFinishPackageDto
{
    public required Guid QuizId { get; init; }
    public required IReadOnlyList<PrepPreviewQuestionFinishDto> Questions { get; init; }
}

public sealed class PrepPreviewDto
{
    public required Guid CatalogItemId { get; init; }
    public required IReadOnlyList<QuestionStudentDto> SampleQuestions { get; init; }
    public PrepPreviewFinishPackageDto? FinishPackage { get; init; }
}

public sealed class PrepMyAccessItemDto
{
    public required Guid CatalogItemId { get; init; }
    public required Guid QuizId { get; init; }
    public required string Title { get; init; }
    public required int QuestionCount { get; init; }
    public required DateTime GrantedAt { get; init; }
    public required DateTime ExpiresAt { get; init; }
    public required bool CanPractice { get; init; }
    public required bool CanPurchase { get; init; }
    public DateTime? LastPracticedAt { get; init; }
}

public sealed class PrepMyAccessesDto
{
    public required IReadOnlyList<PrepMyAccessItemDto> Active { get; init; }
    public required IReadOnlyList<PrepMyAccessItemDto> Expired { get; init; }
}

public class PrepCheckoutRequest
{
    public Guid OfferId { get; set; }
}

public class PrepPayPalCreateOrderRequest
{
    public Guid OfferId { get; set; }
    public string? ReferralCode { get; set; }
}

public class PrepMobilePurchaseRequest
{
    public Guid CatalogItemId { get; set; }
    public Guid OfferId { get; set; }
    public required string Platform { get; set; }
    public required string ProductId { get; set; }
    public required string PurchaseToken { get; set; }
    public string? TransactionId { get; set; }
    public string? ReferralCode { get; set; }
}

public sealed class PrepCheckoutResultDto
{
    public required string Status { get; init; }
    public Guid? PurchaseId { get; init; }
    public DateTime? AccessExpiresAt { get; init; }
    public bool RequiresPayment { get; init; }
    public string? Message { get; init; }
}
