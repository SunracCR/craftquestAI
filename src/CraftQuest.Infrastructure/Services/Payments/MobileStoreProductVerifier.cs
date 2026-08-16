using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class MobileStoreProductVerifier(
    GooglePlayProductVerifier googlePlay,
    AppleAppStoreSubscriptionVerifier apple) : IMobileStoreProductVerifier
{
    public Task<MobileStoreProductDetails> VerifyGooglePlayConsumableAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default) =>
        googlePlay.VerifyAndConsumeAsync(productId, purchaseToken, cancellationToken);

    public Task<MobileStoreProductDetails> VerifyAppStoreConsumableAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken = default) =>
        apple.VerifyConsumableAsync(productId, purchaseToken, transactionId, cancellationToken);
}
