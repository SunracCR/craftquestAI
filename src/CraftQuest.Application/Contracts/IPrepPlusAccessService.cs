namespace CraftQuest.Application.Contracts;

public interface IPrepPlusAccessService
{
    Task<DateTime> GrantOrExtendPurchaseAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        int durationDays,
        Guid? purchaseId,
        CancellationToken cancellationToken = default);
}
