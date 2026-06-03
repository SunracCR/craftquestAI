using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class MobileStoreSubscriptionVerifier(
    GooglePlaySubscriptionVerifier googlePlay,
    AppleAppStoreSubscriptionVerifier apple) : IMobileStoreSubscriptionVerifier
{
    public Task<MobileStoreSubscriptionDetails> VerifyGooglePlayAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken = default) =>
        googlePlay.VerifyAsync(productId, purchaseToken, cancellationToken);

    public Task<MobileStoreSubscriptionDetails> VerifyAppStoreAsync(
        string productId,
        string purchaseToken,
        string? transactionId,
        CancellationToken cancellationToken = default) =>
        apple.VerifyAsync(productId, purchaseToken, transactionId, cancellationToken);
}
