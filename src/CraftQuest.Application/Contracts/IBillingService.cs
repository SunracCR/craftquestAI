using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Application.Contracts;

public interface IBillingService
{
    Task<UserBillingDto> GetMyBillingAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PurchaseHistoryItemDto>> GetMyPurchasesAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task EnsureCanCreateQuizAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Bloquea edición de cuestionarios/preguntas e importaciones cuando el usuario
    /// supera el cupo de cuestionarios propios de su plan (p. ej. Free con 3+ tras bajar de Pro).
    /// </summary>
    Task EnsureCanModifyOwnedQuizzesAsync(
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

    /// <summary>Acredita créditos IA tras compra de paquete (no disponible en plan free).</summary>
    Task<int> GrantPurchasedAiCreditsAsync(
        Guid userId,
        int amount,
        Guid purchaseId,
        CancellationToken cancellationToken = default);

    Task ActivatePlanAsync(
        Guid userId,
        string planCode,
        string providerCode,
        string? providerSubscriptionId,
        SubscriptionActivationOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>Revoca renovación automática; mantiene el plan hasta fin de periodo.</summary>
    Task<CancelAutoRenewResponse> CancelAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    /// <summary>Reactiva renovación automática mientras el periodo pagado sigue vigente.</summary>
    Task<ReactivateAutoRenewResponse> ReactivateAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task CancelSubscriptionAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<bool> IsSubscriptionExpiringAsync(
        Guid userId,
        int withinDays = 7,
        CancellationToken cancellationToken = default);

    Task<int> ProcessExpiredSubscriptionsAsync(
        CancellationToken cancellationToken = default);

    Task RenewSubscriptionPeriodAsync(
        string providerSubscriptionId,
        string providerCode,
        DateTime? periodEnd,
        string? paymentTransactionId,
        CancellationToken cancellationToken = default);
}
