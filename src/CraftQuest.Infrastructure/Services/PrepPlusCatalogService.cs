using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusCatalogService(
    CraftQuestDbContext dbContext,
    IPrepPlusAccessService prepPlusAccessService) : IPrepPlusCatalogService
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    private static readonly HashSet<string> ValidPriceFilters = ["all", "free", "paid"];
    private static readonly HashSet<string> ValidUserAccessFilters = ["all", "none", "active", "expired"];

    public async Task<IReadOnlyList<PrepCategoryPublicDto>> GetPublicCategoryTreeAsync(
        CancellationToken cancellationToken = default)
    {
        var publishedCounts = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Where(i => i.IsPublished && !i.IsDeleted)
            .GroupBy(i => i.CategoryId)
            .Select(g => new { CategoryId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.CategoryId, x => x.Count, cancellationToken);

        var all = await dbContext.PrepCategories
            .AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .ToListAsync(cancellationToken);

        var roots = all.Where(c => c.ParentCategoryId == null).ToList();
        return roots.Select(r => MapPublicCategoryTree(r, all, publishedCounts)).ToList();
    }

    public async Task<IReadOnlyList<PrepCatalogBrowseItemDto>> BrowseCategoryItemsAsync(
        Guid userId,
        Guid categoryId,
        string? search,
        string? priceFilter,
        string? institutionTag,
        IReadOnlyList<string>? tags,
        string? userAccessFilter,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 50);
        skip = Math.Max(0, skip);

        var price = NormalizeFilter(priceFilter, ValidPriceFilters, "all");
        var accessFilter = NormalizeFilter(userAccessFilter, ValidUserAccessFilters, "all");

        await RequireActiveCategoryAsync(categoryId, cancellationToken);

        var now = DateTime.UtcNow;
        var query = dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(i => i.Quiz)
            .Include(i => i.AccessOffers.Where(o => o.IsActive))
            .Where(i => i.IsPublished && !i.IsDeleted && i.CategoryId == categoryId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(i =>
                (i.TitleOverride ?? i.Quiz.Title).Contains(term)
                || (i.Description ?? i.Quiz.Description ?? "").Contains(term)
                || (i.InstitutionTag ?? "").Contains(term)
                || (i.TagsJson ?? "").Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(institutionTag))
        {
            var inst = institutionTag.Trim();
            query = query.Where(i => i.InstitutionTag == inst);
        }

        if (tags is { Count: > 0 })
        {
            foreach (var tag in tags.Where(t => !string.IsNullOrWhiteSpace(t)))
            {
                var token = tag.Trim();
                query = query.Where(i => i.TagsJson != null && i.TagsJson.Contains(token));
            }
        }

        if (price == "free")
        {
            query = query.Where(i => i.AccessOffers.Any(o => o.IsActive && o.IsFree));
        }
        else if (price == "paid")
        {
            query = query.Where(i => i.AccessOffers.Any(o => o.IsActive && !o.IsFree && o.PriceAmount > 0));
        }

        var items = await query
            .OrderBy(i => i.TitleOverride ?? i.Quiz.Title)
            .ToListAsync(cancellationToken);

        var catalogItemIds = items.Select(i => i.CatalogItemId).ToList();
        var accessByItem = await LoadPurchaseAccessByCatalogItemAsync(userId, catalogItemIds, cancellationToken);

        var quizIds = items.Select(i => i.QuizId).Distinct().ToList();
        var questionCounts = await dbContext.Questions
            .Where(q => quizIds.Contains(q.QuizId) && q.DeletedAt == null)
            .GroupBy(q => q.QuizId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);

        var mapped = items
            .Select(i =>
            {
                accessByItem.TryGetValue(i.CatalogItemId, out var access);
                var state = ResolveAccessState(access, now);
                return MapBrowseItem(i, questionCounts.GetValueOrDefault(i.QuizId), state, access, now);
            })
            .Where(i => MatchesUserAccessFilter(i.UserAccessState, accessFilter))
            .Skip(skip)
            .Take(take)
            .ToList();

        return mapped;
    }

    public async Task<PrepCatalogItemPublicDetailDto> GetPublicItemAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedItemAsync(catalogItemId, cancellationToken);
        var now = DateTime.UtcNow;
        var access = await GetPurchaseAccessAsync(userId, item.CatalogItemId, item.QuizId, cancellationToken);
        var state = ResolveAccessState(access, now);
        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == item.QuizId && q.DeletedAt == null, cancellationToken);
        var rootType = await GetRootCategoryTypeAsync(item.CategoryId, cancellationToken);

        return new PrepCatalogItemPublicDetailDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = item.QuizId,
            Title = item.TitleOverride ?? item.Quiz.Title,
            Description = item.Description ?? item.Quiz.Description,
            CategoryId = item.CategoryId,
            CategoryName = item.Category.Name,
            RootCategoryType = rootType,
            Tags = DeserializeTags(item.TagsJson),
            InstitutionTag = item.InstitutionTag,
            QuestionCount = questionCount,
            CanPurchase = CanPurchase(item, now),
            ListingEndsAt = item.ListingEndsAt,
            UserAccessState = state,
            AccessExpiresAt = access?.ExpiresAt,
            CanPractice = state == "active",
            Offers = item.AccessOffers
                .Where(o => o.IsActive)
                .OrderBy(o => o.DurationDays)
                .Select(o => new PrepAccessOfferDto
                {
                    OfferId = o.OfferId,
                    DurationDays = o.DurationDays,
                    PriceAmount = o.PriceAmount,
                    CurrencyCode = o.CurrencyCode,
                    IsFree = o.IsFree,
                    StoreProductId = o.StoreProductId,
                    IsActive = o.IsActive,
                })
                .ToList(),
        };
    }

    public async Task<PrepPreviewDto> GetPreviewAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedItemAsync(catalogItemId, cancellationToken);

        var samples = await dbContext.PrepSampleQuestions
            .AsNoTracking()
            .Where(s => s.CatalogItemId == catalogItemId)
            .OrderBy(s => s.SortOrder)
            .Select(s => s.QuestionId)
            .ToListAsync(cancellationToken);

        if (samples.Count == 0)
        {
            throw new AppException(
                "Preview is not available for this item.",
                404,
                PrepPlusErrorCodes.PreviewNotAvailable);
        }

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Include(q => q.QuestionType)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Where(q => samples.Contains(q.QuestionId) && q.DeletedAt == null)
            .ToListAsync(cancellationToken);

        var ordered = samples
            .Select(id => questions.FirstOrDefault(q => q.QuestionId == id))
            .Where(q => q is not null)
            .Select(q => MapStudentQuestion(q!))
            .ToList();

        return new PrepPreviewDto
        {
            CatalogItemId = catalogItemId,
            SampleQuestions = ordered,
        };
    }

    public async Task<PrepMyAccessesDto> GetMyAccessesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var accesses = await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.AccessType == "purchase" && a.PrepCatalogItemId != null)
            .OrderByDescending(a => a.GrantedAt)
            .ToListAsync(cancellationToken);

        if (accesses.Count == 0)
        {
            return new PrepMyAccessesDto { Active = [], Expired = [] };
        }

        var catalogItemIds = accesses
            .Select(a => a.PrepCatalogItemId!.Value)
            .Distinct()
            .ToList();

        var catalogItems = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(i => i.Quiz)
            .Where(i => catalogItemIds.Contains(i.CatalogItemId))
            .ToDictionaryAsync(i => i.CatalogItemId, cancellationToken);

        var quizIds = catalogItems.Values.Select(i => i.QuizId).Distinct().ToList();
        var questionCounts = await dbContext.Questions
            .Where(q => quizIds.Contains(q.QuizId) && q.DeletedAt == null)
            .GroupBy(q => q.QuizId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);

        var active = new List<PrepMyAccessItemDto>();
        var expired = new List<PrepMyAccessItemDto>();

        foreach (var access in accesses)
        {
            if (!catalogItems.TryGetValue(access.PrepCatalogItemId!.Value, out var item))
            {
                continue;
            }

            var dto = new PrepMyAccessItemDto
            {
                CatalogItemId = item.CatalogItemId,
                QuizId = item.QuizId,
                Title = item.TitleOverride ?? item.Quiz.Title,
                QuestionCount = questionCounts.GetValueOrDefault(item.QuizId),
                GrantedAt = access.GrantedAt,
                ExpiresAt = access.ExpiresAt ?? access.GrantedAt,
                CanPractice = access.ExpiresAt > now,
                CanPurchase = CanPurchase(item, now),
                LastPracticedAt = access.LastPracticedAt,
            };

            if (access.ExpiresAt > now)
            {
                active.Add(dto);
            }
            else
            {
                expired.Add(dto);
            }
        }

        return new PrepMyAccessesDto
        {
            Active = active,
            Expired = expired,
        };
    }

    public async Task<PrepCheckoutResultDto> CheckoutAsync(
        Guid userId,
        Guid catalogItemId,
        PrepCheckoutRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedItemAsync(catalogItemId, cancellationToken);
        var now = DateTime.UtcNow;

        if (!CanPurchase(item, now))
        {
            throw new AppException(
                "This item is not available for purchase.",
                400,
                PrepPlusErrorCodes.ItemNotAvailable);
        }

        var offer = await dbContext.PrepAccessOffers
            .FirstOrDefaultAsync(
                o => o.OfferId == request.OfferId
                    && o.CatalogItemId == catalogItemId
                    && o.IsActive,
                cancellationToken)
            ?? throw new AppException("Offer not found.", 404, PrepPlusErrorCodes.OfferNotFound);

        if (!offer.IsFree)
        {
            return new PrepCheckoutResultDto
            {
                Status = "payment_required",
                RequiresPayment = true,
                Message = "Use PayPal (web) or in-app purchase for paid offers.",
            };
        }

        var expiresAt = await prepPlusAccessService.GrantOrExtendPurchaseAccessAsync(
            userId,
            item.CatalogItemId,
            item.QuizId,
            offer.DurationDays,
            purchaseId: null,
            cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);

        return new PrepCheckoutResultDto
        {
            Status = "granted",
            RequiresPayment = false,
            AccessExpiresAt = expiresAt,
            Message = "Free access granted.",
        };
    }

    private async Task<PrepCatalogItem> LoadPublishedItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        var item = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(i => i.Quiz)
            .Include(i => i.Category)
            .Include(i => i.AccessOffers)
            .FirstOrDefaultAsync(
                i => i.CatalogItemId == catalogItemId && i.IsPublished && !i.IsDeleted,
                cancellationToken);

        if (item is null)
        {
            throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);
        }

        return item;
    }

    private async Task RequireActiveCategoryAsync(Guid categoryId, CancellationToken cancellationToken)
    {
        var exists = await dbContext.PrepCategories
            .AnyAsync(c => c.CategoryId == categoryId && c.IsActive, cancellationToken);
        if (!exists)
        {
            throw new AppException("Category not found.", 404, PrepPlusErrorCodes.CategoryNotFound);
        }
    }

    private async Task<string> GetRootCategoryTypeAsync(
        Guid categoryId,
        CancellationToken cancellationToken)
    {
        var current = await dbContext.PrepCategories
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CategoryId == categoryId, cancellationToken)
            ?? throw new AppException("Category not found.", 404, PrepPlusErrorCodes.CategoryNotFound);

        while (current.ParentCategoryId.HasValue)
        {
            current = await dbContext.PrepCategories
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.CategoryId == current.ParentCategoryId.Value, cancellationToken)
                ?? throw new AppException(
                    "Category hierarchy is broken.",
                    500,
                    PrepPlusErrorCodes.CategoryHierarchyBroken);
        }

        return current.CategoryType;
    }

    private async Task<Dictionary<Guid, QuizAccess>> LoadPurchaseAccessByCatalogItemAsync(
        Guid userId,
        IReadOnlyList<Guid> catalogItemIds,
        CancellationToken cancellationToken)
    {
        if (catalogItemIds.Count == 0)
        {
            return [];
        }

        var accesses = await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId
                && a.AccessType == "purchase"
                && a.PrepCatalogItemId != null
                && catalogItemIds.Contains(a.PrepCatalogItemId.Value))
            .ToListAsync(cancellationToken);

        return accesses
            .GroupBy(a => a.PrepCatalogItemId!.Value)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(a => a.ExpiresAt).First());
    }

    private async Task<QuizAccess?> GetPurchaseAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        return await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId
                && a.QuizId == quizId
                && a.AccessType == "purchase"
                && a.PrepCatalogItemId == catalogItemId)
            .OrderByDescending(a => a.ExpiresAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    private static bool CanPurchase(PrepCatalogItem item, DateTime now) =>
        item.IsPublished
        && !item.IsDeleted
        && (!item.ListingStartsAt.HasValue || item.ListingStartsAt <= now)
        && (!item.ListingEndsAt.HasValue || item.ListingEndsAt > now);

    private static string ResolveAccessState(QuizAccess? access, DateTime now)
    {
        if (access is null || access.ExpiresAt is null)
        {
            return "none";
        }

        return access.ExpiresAt > now ? "active" : "expired";
    }

    private static bool MatchesUserAccessFilter(string state, string filter) =>
        filter switch
        {
            "none" => state == "none",
            "active" => state == "active",
            "expired" => state == "expired",
            _ => true,
        };

    private static PrepCatalogBrowseItemDto MapBrowseItem(
        PrepCatalogItem item,
        int questionCount,
        string userAccessState,
        QuizAccess? access,
        DateTime now)
    {
        var activeOffers = item.AccessOffers.Where(o => o.IsActive).ToList();
        var paidOffers = activeOffers.Where(o => !o.IsFree && o.PriceAmount > 0).ToList();

        return new PrepCatalogBrowseItemDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = item.QuizId,
            Title = item.TitleOverride ?? item.Quiz.Title,
            Description = item.Description ?? item.Quiz.Description,
            QuestionCount = questionCount,
            Tags = DeserializeTags(item.TagsJson),
            InstitutionTag = item.InstitutionTag,
            HasFreeOffer = activeOffers.Any(o => o.IsFree),
            LowestPaidPrice = paidOffers.Count == 0 ? null : paidOffers.Min(o => o.PriceAmount),
            CurrencyCode = paidOffers.FirstOrDefault()?.CurrencyCode,
            UserAccessState = userAccessState,
            AccessExpiresAt = access?.ExpiresAt,
            CanPurchase = CanPurchase(item, now),
        };
    }

    private static PrepCategoryPublicDto MapPublicCategoryTree(
        PrepCategory node,
        List<PrepCategory> all,
        IReadOnlyDictionary<Guid, int> publishedCounts)
    {
        var children = all
            .Where(c => c.ParentCategoryId == node.CategoryId)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .Select(c => MapPublicCategoryTree(c, all, publishedCounts))
            .ToList();

        var directCount = publishedCounts.GetValueOrDefault(node.CategoryId);
        var childCount = children.Sum(c => c.PublishedItemCount);

        return new PrepCategoryPublicDto
        {
            CategoryId = node.CategoryId,
            ParentCategoryId = node.ParentCategoryId,
            CategoryType = node.CategoryType,
            Slug = node.Slug,
            Name = node.Name,
            Description = node.Description,
            CountryCode = node.CountryCode,
            IconKey = node.IconKey,
            PublishedItemCount = directCount + childCount,
            Children = children,
        };
    }

    private static QuestionStudentDto MapStudentQuestion(Question q) => new()
    {
        QuestionId = q.QuestionId,
        QuestionType = q.QuestionType.Code,
        Text = q.QuestionText,
        RandomizeAnswerOptions = q.RandomizeAnswerOptions,
        AnswerOptions = q.AnswerOptions
            .OrderBy(o => o.DefaultSortOrder)
            .Select(o => new AnswerOptionDto
            {
                AnswerOptionId = o.AnswerOptionId,
                StableKey = o.StableKey,
                Text = o.AnswerText,
                MediaAssetId = o.MediaAssetId,
            })
            .ToList(),
    };

    private static string NormalizeFilter(string? value, HashSet<string> valid, string defaultValue)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return defaultValue;
        }

        var normalized = value.Trim().ToLowerInvariant();
        return valid.Contains(normalized) ? normalized : defaultValue;
    }

    private static IReadOnlyList<string> DeserializeTags(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return [];
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(json, JsonOptions) ?? [];
        }
        catch
        {
            return [];
        }
    }
}
