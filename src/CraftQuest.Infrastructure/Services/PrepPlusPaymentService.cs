using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusPaymentService(
    CraftQuestDbContext dbContext,
    PayPalApiClient payPalApiClient,
    IPrepPlusAccessService prepPlusAccessService,
    IPrepReferralService prepReferralService,
    IOptions<PaymentOptions> options) : IPrepPlusPaymentService
{
    private const string ProductType = "prep_access";

    public async Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        Guid catalogItemId,
        Guid offerId,
        string? referralCode = null,
        CancellationToken cancellationToken = default)
    {
        var (item, offer) = await GetOfferContextAsync(
            catalogItemId,
            offerId,
            cancellationToken);

        if (offer.IsFree || offer.PriceAmount <= 0)
        {
            throw new AppException(
                "This offer is free. Use checkout without payment.",
                400,
                PrepPlusErrorCodes.OfferIsFree);
        }

        var referralCodeId = await prepReferralService.ResolveReferralCodeIdAsync(
            referralCode,
            catalogItemId,
            cancellationToken);

        var purchaseId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var productCode = BuildProductCode(catalogItemId, offerId);
        var title = item.TitleOverride ?? item.Quiz.Title;
        var description = $"Preparación+ · {title} · {offer.DurationDays} days";

        if (options.Value.UseMockPayments)
        {
            var mockOrderId = $"MOCK-PREP-{purchaseId:N}";
            await CreatePurchaseAsync(
                purchaseId,
                userId,
                productCode,
                "paypal",
                mockOrderId,
                offer.PriceAmount,
                offer.CurrencyCode,
                "pending",
                now,
                referralCodeId,
                cancellationToken);

            return new PayPalCreateOrderResponse
            {
                PurchaseId = purchaseId,
                OrderId = mockOrderId,
                ApprovalUrl = null,
                MockMode = true,
            };
        }

        var (orderId, approvalUrl) = await payPalApiClient.CreateOrderAsync(
            offer.PriceAmount,
            offer.CurrencyCode,
            description,
            cancellationToken);

        await CreatePurchaseAsync(
            purchaseId,
            userId,
            productCode,
            "paypal",
            orderId,
            offer.PriceAmount,
            offer.CurrencyCode,
            "pending",
            now,
            referralCodeId,
            cancellationToken);

        return new PayPalCreateOrderResponse
        {
            PurchaseId = purchaseId,
            OrderId = orderId,
            ApprovalUrl = approvalUrl,
            MockMode = false,
        };
    }

    public async Task<PrepCheckoutResultDto> CapturePayPalOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var purchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.UserId == userId
                    && p.ProviderCode == "paypal"
                    && p.ProviderTransactionId == request.OrderId
                    && p.ProductType == ProductType,
                cancellationToken)
            ?? throw new AppException(
                "Prep+ PayPal purchase not found.",
                404,
                PrepPlusErrorCodes.PayPalPurchaseNotFound);

        if (purchase.Status == "validated")
        {
            return await BuildGrantedResultFromPurchaseAsync(purchase, cancellationToken);
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        return await FulfillPurchaseAsync(purchase, cancellationToken);
    }

    public async Task<PrepCheckoutResultDto> VerifyMobilePurchaseAsync(
        Guid userId,
        PrepMobilePurchaseRequest request,
        CancellationToken cancellationToken = default)
    {
        var platform = request.Platform.Trim().ToLowerInvariant();
        if (platform is not ("google_play" or "app_store"))
        {
            throw new AppException(
                "Platform must be google_play or app_store.",
                400,
                PrepPlusErrorCodes.MobilePlatformInvalid);
        }

        var (item, offer) = await GetOfferContextAsync(
            request.CatalogItemId,
            request.OfferId,
            cancellationToken);

        if (offer.IsFree)
        {
            throw new AppException(
                "This offer is free. Use checkout without payment.",
                400,
                PrepPlusErrorCodes.OfferIsFree);
        }

        if (!string.IsNullOrWhiteSpace(offer.StoreProductId)
            && !string.Equals(offer.StoreProductId, request.ProductId, StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException(
                "Store product id does not match this offer.",
                400,
                PrepPlusErrorCodes.StoreProductMismatch);
        }

        if (!options.Value.UseMockPayments)
        {
            ValidateStoreConfigured(platform);
        }

        var providerCode = platform == "google_play" ? "google_play" : "app_store";
        var transactionId = request.TransactionId ?? request.PurchaseToken;
        var productCode = BuildProductCode(request.CatalogItemId, request.OfferId);
        var referralCodeId = await prepReferralService.ResolveReferralCodeIdAsync(
            request.ReferralCode,
            request.CatalogItemId,
            cancellationToken);

        var existing = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == providerCode
                    && p.ProviderTransactionId == transactionId,
                cancellationToken);

        if (existing is { Status: "validated", ProductType: ProductType })
        {
            return await BuildGrantedResultFromPurchaseAsync(existing, cancellationToken);
        }

        var purchase = existing ?? new Purchase
        {
            PurchaseId = Guid.NewGuid(),
            UserId = userId,
            ProductCode = productCode,
            ProductType = ProductType,
            ProviderCode = providerCode,
            ProviderTransactionId = transactionId,
            Amount = offer.PriceAmount,
            CurrencyCode = offer.CurrencyCode,
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            PrepReferralCodeId = referralCodeId,
        };

        if (existing is null)
        {
            dbContext.Purchases.Add(purchase);
        }
        else if (referralCodeId.HasValue && existing.PrepReferralCodeId is null)
        {
            existing.PrepReferralCodeId = referralCodeId;
        }

        return await FulfillPurchaseAsync(purchase, cancellationToken);
    }

    private async Task<PrepCheckoutResultDto> FulfillPurchaseAsync(
        Purchase purchase,
        CancellationToken cancellationToken)
    {
        var (catalogItemId, offerId) = ParseProductCode(purchase.ProductCode);
        var offer = await dbContext.PrepAccessOffers
            .Include(o => o.CatalogItem)
            .ThenInclude(i => i.Quiz)
            .FirstOrDefaultAsync(
                o => o.OfferId == offerId && o.CatalogItemId == catalogItemId,
                cancellationToken)
            ?? throw new AppException(
                "Offer no longer exists.",
                404,
                PrepPlusErrorCodes.OfferNoLongerExists);

        purchase.Status = "validated";
        purchase.PurchasedAt = DateTime.UtcNow;

        var expiresAt = await prepPlusAccessService.GrantOrExtendPurchaseAccessAsync(
            purchase.UserId,
            catalogItemId,
            offer.CatalogItem.QuizId,
            offer.DurationDays,
            purchase.PurchaseId,
            cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);

        if (!offer.IsFree && offer.PriceAmount > 0 && purchase.Amount > 0)
        {
            await prepReferralService.ApplyReferralRewardIfApplicableAsync(
                purchase,
                catalogItemId,
                offer.CatalogItem.QuizId,
                cancellationToken);
        }

        return new PrepCheckoutResultDto
        {
            Status = "granted",
            PurchaseId = purchase.PurchaseId,
            RequiresPayment = false,
            AccessExpiresAt = expiresAt,
            Message = "Access granted.",
        };
    }

    private async Task<PrepCheckoutResultDto> BuildGrantedResultFromPurchaseAsync(
        Purchase purchase,
        CancellationToken cancellationToken)
    {
        var access = await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.GrantedByPurchaseId == purchase.PurchaseId)
            .OrderByDescending(a => a.ExpiresAt)
            .FirstOrDefaultAsync(cancellationToken);

        return new PrepCheckoutResultDto
        {
            Status = "granted",
            PurchaseId = purchase.PurchaseId,
            RequiresPayment = false,
            AccessExpiresAt = access?.ExpiresAt,
            Message = "Access already active.",
        };
    }

    private async Task<(PrepCatalogItem Item, PrepAccessOffer Offer)> GetOfferContextAsync(
        Guid catalogItemId,
        Guid offerId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var item = await dbContext.PrepCatalogItems
            .Include(i => i.Quiz)
            .Include(i => i.AccessOffers)
            .FirstOrDefaultAsync(
                i => i.CatalogItemId == catalogItemId && i.IsPublished && !i.IsDeleted,
                cancellationToken)
            ?? throw new AppException(
                "Catalog item not found.",
                404,
                PrepPlusErrorCodes.CatalogItemNotFound);

        if (item.ListingStartsAt.HasValue && item.ListingStartsAt > now
            || item.ListingEndsAt.HasValue && item.ListingEndsAt <= now)
        {
            throw new AppException(
                "This item is not available for purchase.",
                400,
                PrepPlusErrorCodes.ItemNotAvailable);
        }

        var offer = item.AccessOffers
            .FirstOrDefault(o => o.OfferId == offerId && o.IsActive)
            ?? throw new AppException("Offer not found.", 404, PrepPlusErrorCodes.OfferNotFound);

        return (item, offer);
    }

    private async Task CreatePurchaseAsync(
        Guid purchaseId,
        Guid userId,
        string productCode,
        string providerCode,
        string providerTransactionId,
        decimal amount,
        string currencyCode,
        string status,
        DateTime createdAt,
        Guid? prepReferralCodeId,
        CancellationToken cancellationToken)
    {
        dbContext.Purchases.Add(new Purchase
        {
            PurchaseId = purchaseId,
            UserId = userId,
            ProductCode = productCode,
            ProductType = ProductType,
            ProviderCode = providerCode,
            ProviderTransactionId = providerTransactionId,
            Amount = amount,
            CurrencyCode = currencyCode,
            Status = status,
            CreatedAt = createdAt,
            PrepReferralCodeId = prepReferralCodeId,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static string BuildProductCode(Guid catalogItemId, Guid offerId) =>
        $"{catalogItemId:N}|{offerId:N}";

    private static (Guid CatalogItemId, Guid OfferId) ParseProductCode(string productCode)
    {
        var parts = productCode.Split('|', StringSplitOptions.TrimEntries);
        if (parts.Length != 2
            || !Guid.TryParse(parts[0], out var catalogItemId)
            || !Guid.TryParse(parts[1], out var offerId))
        {
            throw new AppException(
                "Invalid prep purchase product code.",
                500,
                PrepPlusErrorCodes.InvalidProductCode);
        }

        return (catalogItemId, offerId);
    }

    private void ValidateStoreConfigured(string platform)
    {
        var mobile = options.Value.Mobile;
        if (platform == "google_play"
            && string.IsNullOrWhiteSpace(mobile.GooglePlayPackageName))
        {
            throw new AppException(
                "Google Play is not configured.",
                503,
                PrepPlusErrorCodes.GooglePlayNotConfigured);
        }

        if (platform == "app_store" && string.IsNullOrWhiteSpace(mobile.AppleSharedSecret))
        {
            throw new AppException(
                "App Store verification requires Payments:Mobile:AppleSharedSecret. " +
                "Use UseMockPayments=true for local development.",
                503,
                PrepPlusErrorCodes.AppStoreNotConfigured);
        }
    }
}
