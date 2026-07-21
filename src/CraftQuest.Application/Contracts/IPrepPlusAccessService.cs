using CraftQuest.Application.Models.PrepPlus;

namespace CraftQuest.Application.Contracts;

public interface IPrepPlusAccessService
{
    Task<PrepAccessGrantResult> GrantOrExtendPurchaseAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        bool isLifetimeAccess,
        int durationDays,
        Guid? purchaseId,
        CancellationToken cancellationToken = default);

    Task EnsureCanPurchaseOfferAsync(
        Guid userId,
        Guid quizId,
        bool isLifetimeOffer,
        CancellationToken cancellationToken = default);
}
