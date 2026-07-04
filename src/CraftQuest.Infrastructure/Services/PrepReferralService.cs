using System.Security.Cryptography;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class PrepReferralService(
    CraftQuestDbContext dbContext,
    IPrepPlusAccessService prepPlusAccessService,
    IMediaService mediaService,
    IOptions<JoinLinkOptions> joinLinkOptions,
    ILogger<PrepReferralService> logger) : IPrepReferralService
{
    private const int RewardDays = 30;
    private const string PrepAccessProductType = "prep_access";
    private readonly JoinLinkOptions _joinLinkOptions = joinLinkOptions.Value;

    public async Task<PrepReferralCodeDto> GetOrCreateReferralCodeAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await dbContext.PrepCatalogItems
            .Include(i => i.Quiz)
            .FirstOrDefaultAsync(
                i => i.CatalogItemId == catalogItemId && i.IsPublished && !i.IsDeleted,
                cancellationToken)
            ?? throw new AppException(
                "Catalog item not found.",
                404,
                PrepPlusErrorCodes.CatalogItemNotFound);

        var slug = await EnsureSlugAsync(item, cancellationToken);

        var existing = await dbContext.PrepReferralCodes
            .AsNoTracking()
            .FirstOrDefaultAsync(
                r => r.ReferrerUserId == userId && r.CatalogItemId == catalogItemId,
                cancellationToken);

        if (existing is not null)
        {
            return MapReferralDto(existing.Code, slug);
        }

        var code = await GenerateUniqueReferralCodeAsync(cancellationToken);
        var entity = new PrepReferralCode
        {
            ReferralCodeId = Guid.NewGuid(),
            Code = code,
            CatalogItemId = catalogItemId,
            ReferrerUserId = userId,
            CreatedAt = DateTime.UtcNow,
            IsActive = true,
        };

        dbContext.PrepReferralCodes.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapReferralDto(code, slug);
    }

    public async Task<Guid?> ResolveReferralCodeIdAsync(
        string? referralCode,
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            return null;
        }

        var normalized = referralCode.Trim().ToUpperInvariant();
        if (!PrepReferralLinkUrlBuilder.IsValidCodeFormat(normalized))
        {
            return null;
        }

        if (!await CatalogItemHasPaidOffersAsync(catalogItemId, cancellationToken))
        {
            return null;
        }

        var entity = await dbContext.PrepReferralCodes
            .AsNoTracking()
            .FirstOrDefaultAsync(
                r => r.Code == normalized
                    && r.CatalogItemId == catalogItemId
                    && r.IsActive,
                cancellationToken);

        return entity?.ReferralCodeId;
    }

    public async Task ApplyReferralRewardIfApplicableAsync(
        Purchase purchase,
        Guid catalogItemId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        if (purchase.PrepReferralCodeId is null)
        {
            logger.LogDebug(
                "Prep referral reward skipped for purchase {PurchaseId}: no referral code on purchase.",
                purchase.PurchaseId);
            return;
        }

        if (purchase.Amount <= 0)
        {
            logger.LogInformation(
                "Prep referral reward skipped for purchase {PurchaseId}: zero-amount purchase.",
                purchase.PurchaseId);
            return;
        }

        if (await dbContext.PrepReferralConversions
                .AnyAsync(c => c.PurchaseId == purchase.PurchaseId, cancellationToken))
        {
            logger.LogDebug(
                "Prep referral reward skipped for purchase {PurchaseId}: conversion already recorded.",
                purchase.PurchaseId);
            return;
        }

        var referral = await dbContext.PrepReferralCodes
            .AsNoTracking()
            .FirstOrDefaultAsync(
                r => r.ReferralCodeId == purchase.PrepReferralCodeId.Value,
                cancellationToken);

        if (referral is null || !referral.IsActive || referral.CatalogItemId != catalogItemId)
        {
            logger.LogWarning(
                "Prep referral reward skipped for purchase {PurchaseId}: referral code missing, inactive, or item mismatch.",
                purchase.PurchaseId);
            return;
        }

        if (referral.ReferrerUserId == purchase.UserId)
        {
            logger.LogInformation(
                "Prep referral reward skipped for purchase {PurchaseId}: self-referral.",
                purchase.PurchaseId);
            return;
        }

        if (!await ReferrerIsEligibleForRewardAsync(
                referral.ReferrerUserId,
                catalogItemId,
                quizId,
                cancellationToken))
        {
            logger.LogInformation(
                "Prep referral reward skipped for purchase {PurchaseId}: referrer {ReferrerUserId} has no prior purchase access for catalog item {CatalogItemId}.",
                purchase.PurchaseId,
                referral.ReferrerUserId,
                catalogItemId);
            return;
        }

        if (await dbContext.PrepReferralConversions.AnyAsync(
                c => c.ReferrerUserId == referral.ReferrerUserId
                    && c.BuyerUserId == purchase.UserId
                    && c.CatalogItemId == catalogItemId,
                cancellationToken))
        {
            logger.LogInformation(
                "Prep referral reward skipped for purchase {PurchaseId}: duplicate referrer/buyer/item conversion.",
                purchase.PurchaseId);
            return;
        }

        await prepPlusAccessService.GrantOrExtendPurchaseAccessAsync(
            referral.ReferrerUserId,
            catalogItemId,
            quizId,
            RewardDays,
            purchaseId: null,
            cancellationToken);

        dbContext.PrepReferralConversions.Add(new PrepReferralConversion
        {
            PrepReferralConversionId = Guid.NewGuid(),
            ReferralCodeId = referral.ReferralCodeId,
            ReferrerUserId = referral.ReferrerUserId,
            BuyerUserId = purchase.UserId,
            CatalogItemId = catalogItemId,
            PurchaseId = purchase.PurchaseId,
            RewardDaysGranted = RewardDays,
            CreatedAt = DateTime.UtcNow,
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        logger.LogInformation(
            "Prep referral reward granted: referrer {ReferrerUserId} +{RewardDays}d on catalog item {CatalogItemId} from purchase {PurchaseId}.",
            referral.ReferrerUserId,
            RewardDays,
            catalogItemId,
            purchase.PurchaseId);
    }

    public async Task<PrepReferralLandingPreviewDto?> GetLandingPreviewAsync(
        string slug,
        CancellationToken cancellationToken = default)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var item = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(i => i.Quiz)
            .Include(i => i.Category)
            .Include(i => i.AccessOffers)
            .FirstOrDefaultAsync(
                i => i.Slug == normalizedSlug && i.IsPublished && !i.IsDeleted,
                cancellationToken);

        if (item is null)
        {
            return null;
        }

        var activeOffers = item.AccessOffers.Where(o => o.IsActive).ToList();
        var paidOffers = activeOffers.Where(o => !o.IsFree && o.PriceAmount > 0).ToList();
        var bestOffer = activeOffers.OrderBy(o => o.DurationDays).FirstOrDefault();

        return new PrepReferralLandingPreviewDto
        {
            Slug = normalizedSlug,
            Title = item.TitleOverride ?? item.Quiz.Title,
            Description = item.Description ?? item.Quiz.Description,
            CategoryName = item.Category.Name,
            LowestPaidPrice = paidOffers.Count > 0 ? paidOffers.Min(o => o.PriceAmount) : null,
            CurrencyCode = paidOffers.FirstOrDefault()?.CurrencyCode ?? bestOffer?.CurrencyCode,
            CoverMediaUrl = BuildCoverMediaUrl(item.CoverMediaId),
        };
    }

    private string? BuildCoverMediaUrl(Guid? coverMediaId)
    {
        if (coverMediaId is null)
        {
            return null;
        }

        return PrepReferralLinkUrlBuilder.ToAbsoluteUrl(
            _joinLinkOptions,
            mediaService.BuildPublicUrl(coverMediaId.Value));
    }

    private Task<bool> CatalogItemHasPaidOffersAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken) =>
        dbContext.PrepAccessOffers.AnyAsync(
            o => o.CatalogItemId == catalogItemId
                && o.IsActive
                && !o.IsFree
                && o.PriceAmount > 0,
            cancellationToken);

    private async Task<bool> ReferrerIsEligibleForRewardAsync(
        Guid referrerUserId,
        Guid catalogItemId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        if (await dbContext.QuizAccesses.AnyAsync(
                a => a.UserId == referrerUserId
                    && a.AccessType == "purchase"
                    && (a.PrepCatalogItemId == catalogItemId || a.QuizId == quizId),
                cancellationToken))
        {
            return true;
        }

        var productPrefix = $"{catalogItemId:N}|";
        return await dbContext.Purchases.AnyAsync(
            p => p.UserId == referrerUserId
                && p.ProductType == PrepAccessProductType
                && p.Status == "validated"
                && p.ProductCode.StartsWith(productPrefix),
            cancellationToken);
    }

    private PrepReferralCodeDto MapReferralDto(string code, string slug) =>
        new()
        {
            Code = code,
            Slug = slug,
            ShareUrl = PrepReferralLinkUrlBuilder.BuildShareUrl(_joinLinkOptions, slug, code),
        };

    private async Task<string> EnsureSlugAsync(
        PrepCatalogItem item,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(item.Slug))
        {
            return item.Slug.Trim().ToLowerInvariant();
        }

        var title = item.TitleOverride ?? item.Quiz.Title;
        var baseSlug = PrepSlugHelper.GenerateFromTitle(title, item.CatalogItemId);
        var slug = baseSlug;
        var suffix = 1;

        while (await dbContext.PrepCatalogItems.AnyAsync(
                   i => i.Slug == slug && i.CatalogItemId != item.CatalogItemId,
                   cancellationToken))
        {
            slug = $"{baseSlug}-{suffix}";
            suffix++;
        }

        item.Slug = slug;
        await dbContext.SaveChangesAsync(cancellationToken);
        return slug;
    }

    private async Task<string> GenerateUniqueReferralCodeAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var suffix = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
            var code = $"PR-{suffix}";
            var exists = await dbContext.PrepReferralCodes
                .AnyAsync(r => r.Code == code, cancellationToken);
            if (!exists)
            {
                return code;
            }
        }

        throw new AppException("Could not generate a unique referral code.", 500);
    }
}
