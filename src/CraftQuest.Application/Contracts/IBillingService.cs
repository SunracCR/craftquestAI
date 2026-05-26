using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Application.Contracts;

public interface IBillingService
{
    Task<UserBillingDto> GetMyBillingAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task EnsureCanCreateQuizAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task EnsureCanAddQuestionAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<QuizQuestionCapacityDto> GetQuizQuestionCapacityAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task EnsureCanCreateShareCodeAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task EnsureCanRedeemSharedQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task EnsureCanInviteUserToQuizAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task AssignFreePlanAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task EnsureHasAiCreditsAsync(
        Guid userId,
        int amount,
        CancellationToken cancellationToken = default);

    Task ConsumeAiCreditsAsync(
        Guid userId,
        int amount,
        string? referenceType,
        Guid? referenceId,
        CancellationToken cancellationToken = default,
        bool saveImmediately = true);

    Task ActivatePlanAsync(
        Guid userId,
        string planCode,
        string providerCode,
        string? providerSubscriptionId,
        CancellationToken cancellationToken = default);

    Task CancelSubscriptionAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<bool> IsSubscriptionExpiringAsync(
        Guid userId,
        int withinDays = 7,
        CancellationToken cancellationToken = default);
}
