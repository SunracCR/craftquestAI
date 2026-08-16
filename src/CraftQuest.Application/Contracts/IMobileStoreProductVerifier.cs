using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Application.Contracts;

public interface IMobileStoreProductVerifier
{
    Task<MobileStoreProductDetails> VerifyGooglePlayConsumableAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default);

    Task<MobileStoreProductDetails> VerifyAppStoreConsumableAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken = default);

    Task ConsumeGooglePlayConsumableAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default);
}
