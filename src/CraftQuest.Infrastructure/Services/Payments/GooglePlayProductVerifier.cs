using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using Google;
using Google.Apis.AndroidPublisher.v3;
using Google.Apis.AndroidPublisher.v3.Data;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class GooglePlayProductVerifier(
    IOptions<PaymentOptions> options,
    ILogger<GooglePlayProductVerifier> logger)
{
    private const int LegacyPurchaseStatePurchased = 0;
    private const int LegacyConsumptionStateNotConsumed = 0;

    public async Task<MobileStoreProductDetails> VerifyAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var snapshot = await GetPurchaseSnapshotAsync(productId, purchaseToken, cancellationToken);

        if (!snapshot.IsPurchased)
        {
            throw new AppException(
                "Google Play product purchase is not in purchased state.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        return new MobileStoreProductDetails
        {
            IsValid = true,
            TransactionId = snapshot.OrderId ?? purchaseToken,
        };
    }

    public async Task ConsumeAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var snapshot = await GetPurchaseSnapshotAsync(productId, purchaseToken, cancellationToken);

        if (!snapshot.IsPurchased || snapshot.IsConsumed)
        {
            return;
        }

        var service = CreateService();
        var packageName = options.Value.Mobile.GooglePlayPackageName;
        await service.Purchases.Products
            .Consume(packageName, productId, purchaseToken)
            .ExecuteAsync(cancellationToken);
    }

    private async Task<GooglePlayProductPurchaseSnapshot> GetPurchaseSnapshotAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var service = CreateService();
        var packageName = options.Value.Mobile.GooglePlayPackageName;

        GoogleApiException? v2Error = null;
        try
        {
            var purchaseV2 = await service.Purchases.Productsv2
                .Getproductpurchasev2(packageName, purchaseToken)
                .ExecuteAsync(cancellationToken);

            return MapProductPurchaseV2(purchaseV2, productId);
        }
        catch (GoogleApiException ex)
        {
            v2Error = ex;
            logger.LogWarning(
                ex,
                "Google Play productsv2.getproductpurchasev2 failed for product {ProductId}.",
                productId);
        }

        try
        {
            var purchase = await service.Purchases.Products
                .Get(packageName, productId, purchaseToken)
                .ExecuteAsync(cancellationToken);

            return new GooglePlayProductPurchaseSnapshot
            {
                IsPurchased = purchase.PurchaseState == LegacyPurchaseStatePurchased,
                IsConsumed = purchase.ConsumptionState != LegacyConsumptionStateNotConsumed,
                OrderId = purchase.OrderId,
            };
        }
        catch (GoogleApiException ex)
        {
            logger.LogError(
                ex,
                "Google Play product verification failed for product {ProductId}. productsv2 error: {V2Message}",
                productId,
                v2Error?.Message);

            throw new AppException(
                "Google Play product purchase could not be verified.",
                502,
                "STORE_PURCHASE_VERIFY_FAILED");
        }
    }

    private static GooglePlayProductPurchaseSnapshot MapProductPurchaseV2(
        ProductPurchaseV2 purchase,
        string expectedProductId)
    {
        var lineItems = purchase.ProductLineItem ?? [];
        var lineItem = lineItems.FirstOrDefault(item =>
            string.Equals(item.ProductId, expectedProductId, StringComparison.OrdinalIgnoreCase));

        if (lineItems.Count > 0 && lineItem is null)
        {
            throw new AppException(
                "Google Play purchase product does not match the requested pack.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        lineItem ??= lineItems.FirstOrDefault();

        var purchaseState = purchase.PurchaseStateContext?.PurchaseState;
        var consumptionState = lineItem?.ProductOfferDetails?.ConsumptionState;

        return new GooglePlayProductPurchaseSnapshot
        {
            IsPurchased = string.Equals(purchaseState, "PURCHASED", StringComparison.OrdinalIgnoreCase),
            IsConsumed = IsV2ConsumptionStateConsumed(consumptionState),
            OrderId = purchase.OrderId,
        };
    }

    private static bool IsV2ConsumptionStateConsumed(string? consumptionState)
    {
        if (string.IsNullOrWhiteSpace(consumptionState))
        {
            return false;
        }

        return consumptionState.Contains("CONSUMED", StringComparison.OrdinalIgnoreCase)
            && !consumptionState.Contains("YET", StringComparison.OrdinalIgnoreCase);
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

    private sealed class GooglePlayProductPurchaseSnapshot
    {
        public required bool IsPurchased { get; init; }
        public required bool IsConsumed { get; init; }
        public string? OrderId { get; init; }
    }
}
