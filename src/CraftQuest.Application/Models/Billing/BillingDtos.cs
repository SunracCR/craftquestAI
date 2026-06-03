namespace CraftQuest.Application.Models.Billing;

public sealed class UserBillingDto
{
    public required PlanDto Plan { get; init; }
    public required SubscriptionDto Subscription { get; init; }
    public required BillingUsageDto Usage { get; init; }
    public required PlanEntitlementsDto Entitlements { get; init; }
    public required CreditBalancesDto Credits { get; init; }
}

public sealed class PlanDto
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public decimal? MonthlyPrice { get; init; }
    public decimal? AnnualPrice { get; init; }
    public bool IsTeacherPlan { get; init; }
    public bool IsInstitutionPlan { get; init; }
}

public sealed class SubscriptionDto
{
    public required string Status { get; init; }
    public required DateTime StartedAt { get; init; }
    public DateTime? EndsAt { get; init; }
    public string BillingCycle { get; init; } = "monthly";
    public bool AutoRenewEnabled { get; init; } = true;
    public bool CancelAtPeriodEnd { get; init; }
    public DateTime? LastPaymentAt { get; init; }
    public DateTime? NextBillingAt { get; init; }
    public string? ProviderCode { get; init; }
    public bool IsRecurring { get; init; }
}

public sealed class BillingUsageDto
{
    public required int QuizzesCreated { get; init; }
    public required int ShareCodesCreatedThisMonth { get; init; }
}

public sealed class PlanEntitlementsDto
{
    public int? MaxQuizzes { get; init; }
    public int? MaxQuestionsPerQuiz { get; init; }
    public required int MonthlyAiCredits { get; init; }
    public required int MonthlyShareCodes { get; init; }
    public int? MaxRedeemedSharedQuizzes { get; init; }
    public required int CurrentRedeemedSharedQuizzes { get; init; }
    public bool CanInviteUsersDirectly { get; init; }
}

public sealed class CreditBalancesDto
{
    public required int AiCredits { get; init; }
    public required int ShareCodeCredits { get; init; }
}

public sealed class QuizQuestionCapacityDto
{
    public required string PlanCode { get; init; }
    public required string PlanName { get; init; }
    public int? MaxQuestionsPerQuiz { get; init; }
    public required int CurrentQuestionCount { get; init; }
    public required int RemainingSlots { get; init; }
}

public sealed class PurchaseHistoryItemDto
{
    public required Guid PurchaseId { get; init; }
    public required string ProductCode { get; init; }
    public string? ProductDisplayName { get; init; }
    public required string ProductType { get; init; }
    public required string ProviderCode { get; init; }
    public decimal? Amount { get; init; }
    public string? CurrencyCode { get; init; }
    public required string Status { get; init; }
    public DateTime? PurchasedAt { get; init; }
    public required DateTime CreatedAt { get; init; }
}
