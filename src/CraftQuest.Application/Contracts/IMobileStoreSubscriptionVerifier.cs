using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Application.Contracts;

public interface IMobileStoreSubscriptionVerifier
{
    Task<MobileStoreSubscriptionDetails> VerifyGooglePlayAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default);

    Task<MobileStoreSubscriptionDetails> VerifyAppStoreAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken = default);
}
