using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using Google.Apis.AndroidPublisher.v3;
using Google.Apis.AndroidPublisher.v3.Data;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Services;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class GooglePlayProductVerifier(IOptions<PaymentOptions> options)
{
    private const int PurchaseStatePurchased = 0;
    private const int ConsumptionStateNotConsumed = 0;

    public async Task<MobileStoreProductDetails> VerifyAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var purchase = await GetProductPurchaseAsync(productId, purchaseToken, cancellationToken);

        if (purchase.PurchaseState != PurchaseStatePurchased)
        {
            throw new AppException(
                "Google Play product purchase is not in purchased state.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        var transactionId = string.IsNullOrWhiteSpace(purchase.OrderId)
            ? purchaseToken
            : purchase.OrderId;

        return new MobileStoreProductDetails
        {
            IsValid = true,
            TransactionId = transactionId,
        };
    }

    public async Task ConsumeAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var purchase = await GetProductPurchaseAsync(productId, purchaseToken, cancellationToken);

        if (purchase.PurchaseState != PurchaseStatePurchased)
        {
            return;
        }

        if (purchase.ConsumptionState != ConsumptionStateNotConsumed)
        {
            return;
        }

        var service = CreateService();
        var packageName = options.Value.Mobile.GooglePlayPackageName;
        await service.Purchases.Products
            .Consume(packageName, productId, purchaseToken)
            .ExecuteAsync(cancellationToken);
    }

    private async Task<ProductPurchase> GetProductPurchaseAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var service = CreateService();
        var packageName = options.Value.Mobile.GooglePlayPackageName;

        try
        {
            return await service.Purchases.Products
                .Get(packageName, productId, purchaseToken)
                .ExecuteAsync(cancellationToken);
        }
        catch (Exception)
        {
            throw new AppException(
                "Google Play product purchase could not be verified.",
                502,
                "STORE_PURCHASE_VERIFY_FAILED");
        }
    }

    private AndroidPublisherService CreateService()
    {
        var mobile = options.Value.Mobile;
        if (string.IsNullOrWhiteSpace(mobile.GooglePlayPackageName))
        {
            throw new AppException("Google Play package name is not configured.", 503);
        }

        if (string.IsNullOrWhiteSpace(mobile.GooglePlayServiceAccountJsonPath)
            || !File.Exists(mobile.GooglePlayServiceAccountJsonPath))
        {
            throw new AppException(
                "Google Play service account JSON is not configured.",
                503);
        }

        var credential = GoogleCredential.FromFile(mobile.GooglePlayServiceAccountJsonPath)
            .CreateScoped(AndroidPublisherService.Scope.Androidpublisher);

        return new AndroidPublisherService(new BaseClientService.Initializer
        {
            HttpClientInitializer = credential,
            ApplicationName = "CraftQuest",
        });
    }
}
