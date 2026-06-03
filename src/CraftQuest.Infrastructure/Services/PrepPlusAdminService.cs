using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusAdminService(CraftQuestDbContext dbContext) : IPrepPlusAdminService
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public async Task<IReadOnlyList<PrepCategoryDto>> GetCategoryTreeAsync(
        bool includeInactive = false,
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.PrepCategories.AsNoTracking();
        if (!includeInactive)
        {
            query = query.Where(c => c.IsActive);
        }

        var all = await query
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .ToListAsync(cancellationToken);

        // Ocultar clones huérfanos: raíz con el mismo slug que ya existe como subcategoría.
        var childSlugs = all
            .Where(c => c.ParentCategoryId != null)
            .Select(c => NormalizeSlug(c.Slug))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var roots = all
            .Where(c => c.ParentCategoryId == null
                && !childSlugs.Contains(NormalizeSlug(c.Slug)))
            .ToList();

        return roots.Select(r => MapCategoryTree(r, all)).ToList();
    }

    public async Task<PrepCategoryDto> CreateCategoryAsync(
        UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidateCategoryRequestAsync(request, null, cancellationToken);

        var entity = new PrepCategory
        {
            CategoryId = Guid.NewGuid(),
            ParentCategoryId = request.ParentCategoryId,
            CategoryType = request.CategoryType.Trim().ToLowerInvariant(),
            Slug = NormalizeSlug(request.Slug),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            CountryCode = request.CountryCode?.Trim(),
            IconKey = request.IconKey?.Trim(),
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.PrepCategories.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapCategory(entity);
    }

    public async Task<PrepCategoryDto> UpdateCategoryAsync(
        Guid categoryId,
        UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCategories
            .FirstOrDefaultAsync(c => c.CategoryId == categoryId, cancellationToken)
            ?? throw new AppException("Category not found.", 404, PrepPlusErrorCodes.CategoryNotFound);

        // No convertir subcategoría en raíz si el cliente omite o envía parentCategoryId nulo.
        var resolvedParentId = request.ParentCategoryId ?? entity.ParentCategoryId;
        var resolvedType = string.IsNullOrWhiteSpace(request.CategoryType)
            ? entity.CategoryType
            : request.CategoryType.Trim().ToLowerInvariant();

        var validationRequest = new UpsertPrepCategoryRequest
        {
            ParentCategoryId = resolvedParentId,
            CategoryType = resolvedType,
            Slug = request.Slug,
            Name = request.Name,
            Description = request.Description,
            CountryCode = request.CountryCode,
            IconKey = request.IconKey,
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
        };
        await ValidateCategoryRequestAsync(validationRequest, categoryId, cancellationToken);

        // Mantener el padre actual salvo reasignación explícita a otro padre.
        if (request.ParentCategoryId.HasValue
            && request.ParentCategoryId != entity.ParentCategoryId)
        {
            entity.ParentCategoryId = request.ParentCategoryId;
        }
        entity.CategoryType = resolvedType;
        entity.Slug = NormalizeSlug(request.Slug);
        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.CountryCode = request.CountryCode?.Trim();
        entity.IconKey = request.IconKey?.Trim();
        entity.SortOrder = request.SortOrder;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);
        return MapCategory(entity);
    }

    public async Task DeleteCategoryAsync(Guid categoryId, CancellationToken cancellationToken = default)
    {
        var all = await dbContext.PrepCategories.ToListAsync(cancellationToken);
        if (all.All(c => c.CategoryId != categoryId))
        {
            throw new AppException("Category not found.", 404, PrepPlusErrorCodes.CategoryNotFound);
        }

        var subtreeIds = CollectSubtreeCategoryIds(categoryId, all);

        var hasItems = await dbContext.PrepCatalogItems
            .AnyAsync(
                i => subtreeIds.Contains(i.CategoryId) && !i.IsDeleted,
                cancellationToken);
        if (hasItems)
        {
            throw new AppException(
                "Cannot delete a category tree that has catalog items.",
                400,
                PrepPlusErrorCodes.CategoryHasItems);
        }

        var toDelete = all.Where(c => subtreeIds.Contains(c.CategoryId)).ToList();
        while (toDelete.Count > 0)
        {
            var leaves = toDelete
                .Where(c => toDelete.All(x => x.ParentCategoryId != c.CategoryId))
                .ToList();
            if (leaves.Count == 0)
            {
                throw new AppException(
                    "Category hierarchy is invalid.",
                    400,
                    PrepPlusErrorCodes.CategoryHierarchyBroken);
            }

            dbContext.PrepCategories.RemoveRange(leaves);
            toDelete.RemoveAll(c => leaves.Contains(c));
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<PrepLinkableQuizDto>> ListLinkableQuizzesAsync(
        string? search = null,
        int take = 100,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 200);

        var adminUserIds = await dbContext.UserRoles
            .AsNoTracking()
            .Where(ur =>
                ur.Role.Code == RoleCodes.ContentAdmin
                || ur.Role.Code == RoleCodes.SuperAdmin)
            .Select(ur => ur.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        if (adminUserIds.Count == 0)
        {
            return [];
        }

        var catalogQuizIds = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Where(i => !i.IsDeleted)
            .Select(i => i.QuizId)
            .ToListAsync(cancellationToken);

        var query = dbContext.Quizzes
            .AsNoTracking()
            .Where(q =>
                q.DeletedAt == null
                && adminUserIds.Contains(q.CreatedByUserId)
                && !catalogQuizIds.Contains(q.QuizId));

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(q =>
                q.Title.Contains(term)
                || (q.Description != null && q.Description.Contains(term)));
        }

        var quizzes = await query
            .OrderByDescending(q => q.UpdatedAt ?? q.CreatedAt)
            .Take(take)
            .ToListAsync(cancellationToken);

        if (quizzes.Count == 0)
        {
            return [];
        }

        var quizIds = quizzes.Select(q => q.QuizId).ToList();
        var questionCounts = await dbContext.Questions
            .Where(q => quizIds.Contains(q.QuizId) && q.DeletedAt == null)
            .GroupBy(q => q.QuizId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);

        var ownerIds = quizzes.Select(q => q.CreatedByUserId).Distinct().ToList();
        var owners = await dbContext.Users
            .AsNoTracking()
            .Where(u => ownerIds.Contains(u.UserId))
            .ToDictionaryAsync(
                u => u.UserId,
                u => u.DisplayName ?? u.Email,
                cancellationToken);

        return quizzes
            .Select(q => new PrepLinkableQuizDto
            {
                QuizId = q.QuizId,
                Title = q.Title,
                Description = q.Description,
                PublicationStatus = q.PublicationStatus,
                QuestionCount = questionCounts.GetValueOrDefault(q.QuizId),
                CreatedByUserId = q.CreatedByUserId,
                CreatedByDisplayName = owners.GetValueOrDefault(q.CreatedByUserId) ?? string.Empty,
            })
            .ToList();
    }

    public async Task<IReadOnlyList<PrepCatalogItemSummaryDto>> ListCatalogItemsAsync(
        Guid? categoryId,
        bool? isPublished,
        bool includeDeleted,
        string? search,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 100);
        skip = Math.Max(0, skip);

        var query = dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(i => i.Quiz)
            .Include(i => i.Category)
            .Include(i => i.AccessOffers)
            .Include(i => i.SampleQuestions)
            .AsQueryable();

        if (!includeDeleted)
        {
            query = query.Where(i => !i.IsDeleted);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(i => i.CategoryId == categoryId.Value);
        }

        if (isPublished.HasValue)
        {
            query = query.Where(i => i.IsPublished == isPublished.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(i =>
                (i.TitleOverride ?? i.Quiz.Title).Contains(term)
                || (i.Description ?? i.Quiz.Description ?? "").Contains(term)
                || (i.InstitutionTag ?? "").Contains(term)
                || (i.TagsJson ?? "").Contains(term));
        }

        var items = await query
            .OrderByDescending(i => i.UpdatedAt ?? i.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        var quizIds = items.Select(i => i.QuizId).Distinct().ToList();
        var questionCounts = await dbContext.Questions
            .Where(q => quizIds.Contains(q.QuizId))
            .GroupBy(q => q.QuizId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);

        return items
            .Select(i => MapSummary(i, questionCounts.GetValueOrDefault(i.QuizId)))
            .ToList();
    }

    public async Task<PrepCatalogItemDetailDto> GetCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(item, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> CreateCatalogItemAsync(
        Guid adminUserId,
        CreatePrepCatalogItemRequest request,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .FirstOrDefaultAsync(q => q.QuizId == request.QuizId && q.DeletedAt == null, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404, PrepPlusErrorCodes.QuizNotFound);

        await EnsureQuizLinkableAsync(quiz, cancellationToken);

        if (await dbContext.PrepCatalogItems.AnyAsync(i => i.QuizId == request.QuizId && !i.IsDeleted, cancellationToken))
        {
            throw new AppException(
                "This quiz is already in the Preparación+ catalog.",
                400,
                PrepPlusErrorCodes.QuizAlreadyInCatalog);
        }

        var category = await RequireCategoryAsync(request.CategoryId, cancellationToken);
        await ValidateInstitutionTagAsync(category.CategoryId, request.InstitutionTag, cancellationToken);

        var entity = new PrepCatalogItem
        {
            CatalogItemId = Guid.NewGuid(),
            QuizId = request.QuizId,
            CategoryId = request.CategoryId,
            TitleOverride = request.TitleOverride?.Trim(),
            Description = request.Description?.Trim(),
            CoverMediaId = request.CoverMediaId,
            TagsJson = SerializeTags(request.Tags),
            InstitutionTag = request.InstitutionTag?.Trim(),
            ListingStartsAt = request.ListingStartsAt,
            ListingEndsAt = request.ListingEndsAt,
            IsPublished = false,
            CreatedByUserId = adminUserId,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.PrepCatalogItems.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(entity.CatalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> UpdateCatalogItemAsync(
        Guid catalogItemId,
        UpdatePrepCatalogItemRequest request,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        await RequireCategoryAsync(request.CategoryId, cancellationToken);
        await ValidateInstitutionTagAsync(request.CategoryId, request.InstitutionTag, cancellationToken);

        entity.CategoryId = request.CategoryId;
        entity.TitleOverride = request.TitleOverride?.Trim();
        entity.Description = request.Description?.Trim();
        entity.CoverMediaId = request.CoverMediaId;
        entity.TagsJson = SerializeTags(request.Tags);
        entity.InstitutionTag = request.InstitutionTag?.Trim();
        entity.ListingStartsAt = request.ListingStartsAt;
        entity.ListingEndsAt = request.ListingEndsAt;
        entity.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> UpsertOffersAsync(
        Guid catalogItemId,
        UpsertPrepAccessOffersRequest request,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .Include(i => i.AccessOffers)
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        ValidateOffers(request.Offers);

        var existingByDuration = entity.AccessOffers.ToDictionary(o => o.DurationDays);
        var requestedDurations = new HashSet<int>();

        foreach (var input in request.Offers)
        {
            requestedDurations.Add(input.DurationDays);
            if (existingByDuration.TryGetValue(input.DurationDays, out var offer))
            {
                offer.PriceAmount = input.IsFree ? 0 : input.PriceAmount;
                offer.CurrencyCode = input.CurrencyCode.Trim().ToUpperInvariant();
                offer.IsFree = input.IsFree;
                offer.StoreProductId = input.StoreProductId?.Trim();
                offer.IsActive = input.IsActive;
            }
            else
            {
                dbContext.PrepAccessOffers.Add(new PrepAccessOffer
                {
                    OfferId = Guid.NewGuid(),
                    CatalogItemId = catalogItemId,
                    DurationDays = input.DurationDays,
                    PriceAmount = input.IsFree ? 0 : input.PriceAmount,
                    CurrencyCode = input.CurrencyCode.Trim().ToUpperInvariant(),
                    IsFree = input.IsFree,
                    StoreProductId = input.StoreProductId?.Trim(),
                    IsActive = input.IsActive,
                });
            }
        }

        foreach (var offer in entity.AccessOffers.Where(o => !requestedDurations.Contains(o.DurationDays)))
        {
            offer.IsActive = false;
        }

        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> UpsertSampleQuestionsAsync(
        Guid catalogItemId,
        UpsertPrepSampleQuestionsRequest request,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .Include(i => i.SampleQuestions)
            .Include(i => i.Quiz)
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        var questionIds = request.QuestionIds.Distinct().ToList();
        if (questionIds.Count != PrepPlusConstants.RequiredSampleQuestionCount)
        {
            throw new AppException(
                $"Exactly {PrepPlusConstants.RequiredSampleQuestionCount} sample questions are required.",
                400,
                PrepPlusErrorCodes.SampleCountRequired,
                new Dictionary<string, object?>
                {
                    ["requiredCount"] = PrepPlusConstants.RequiredSampleQuestionCount,
                });
        }

        var validCount = await dbContext.Questions
            .CountAsync(
                q => q.QuizId == entity.QuizId && questionIds.Contains(q.QuestionId),
                cancellationToken);
        if (validCount != questionIds.Count)
        {
            throw new AppException(
                "All sample questions must belong to the linked quiz.",
                400,
                PrepPlusErrorCodes.SampleQuestionsNotInQuiz);
        }

        dbContext.PrepSampleQuestions.RemoveRange(entity.SampleQuestions);
        for (var i = 0; i < questionIds.Count; i++)
        {
            dbContext.PrepSampleQuestions.Add(new PrepSampleQuestion
            {
                CatalogItemId = catalogItemId,
                QuestionId = questionIds[i],
                SortOrder = i + 1,
            });
        }

        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> PublishCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .Include(i => i.AccessOffers)
            .Include(i => i.SampleQuestions)
            .Include(i => i.Quiz)
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        await ValidatePublishableAsync(entity, cancellationToken);

        entity.IsPublished = true;
        entity.PublishedAt = DateTime.UtcNow;
        entity.UpdatedAt = DateTime.UtcNow;

        entity.Quiz.Visibility = "curated";
        entity.Quiz.IsCurated = true;
        entity.Quiz.PublicationStatus = "published";
        entity.Quiz.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> UnpublishCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        entity.IsPublished = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var loaded = await LoadCatalogItemDetailAsync(catalogItemId, cancellationToken);
        return await MapDetailAsync(loaded, cancellationToken);
    }

    public async Task DeleteCatalogItemAsync(Guid catalogItemId, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.PrepCatalogItems
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);

        entity.IsDeleted = true;
        entity.IsPublished = false;
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<PrepCatalogItem> LoadCatalogItemDetailAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        return await dbContext.PrepCatalogItems
            .Include(i => i.Quiz)
            .Include(i => i.Category)
            .Include(i => i.AccessOffers)
            .Include(i => i.SampleQuestions)
            .ThenInclude(s => s.Question)
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404, PrepPlusErrorCodes.CatalogItemNotFound);
    }

    private async Task ValidateCategoryRequestAsync(
        UpsertPrepCategoryRequest request,
        Guid? updatingCategoryId,
        CancellationToken cancellationToken)
    {
        var categoryType = request.CategoryType.Trim().ToLowerInvariant();
        if (categoryType is not PrepPlusConstants.CategoryTypes.Geographic
            and not PrepPlusConstants.CategoryTypes.Thematic)
        {
            throw new AppException("Invalid category type.", 400, PrepPlusErrorCodes.InvalidCategoryType);
        }

        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Slug))
        {
            throw new AppException("Name and slug are required.", 400, PrepPlusErrorCodes.NameSlugRequired);
        }

        var slug = NormalizeSlug(request.Slug);

        if (request.ParentCategoryId.HasValue)
        {
            var parent = await dbContext.PrepCategories
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.CategoryId == request.ParentCategoryId.Value, cancellationToken)
                ?? throw new AppException(
                    "Parent category not found.",
                    404,
                    PrepPlusErrorCodes.ParentCategoryNotFound);

            if (parent.CategoryType != categoryType)
            {
                throw new AppException(
                    "Subcategory type must match parent type.",
                    400,
                    PrepPlusErrorCodes.SubcategoryTypeMismatch);
            }

            if (updatingCategoryId.HasValue && request.ParentCategoryId == updatingCategoryId)
            {
                throw new AppException(
                    "A category cannot be its own parent.",
                    400,
                    PrepPlusErrorCodes.CategorySelfParent);
            }
        }
        else if (categoryType == PrepPlusConstants.CategoryTypes.Thematic
                 && !string.Equals(slug, "internacional", StringComparison.OrdinalIgnoreCase)
                 && !string.Equals(request.Name.Trim(), "Internacional", StringComparison.OrdinalIgnoreCase))
        {
            // Root thematic categories are allowed (e.g. Internacional); no hard block for other roots.
        }

        var slugTaken = await dbContext.PrepCategories.AnyAsync(
            c => c.ParentCategoryId == request.ParentCategoryId
                 && c.Slug == slug
                 && (!updatingCategoryId.HasValue || c.CategoryId != updatingCategoryId.Value),
            cancellationToken);
        if (slugTaken)
        {
            throw new AppException(
                "Slug already exists for this parent category.",
                400,
                PrepPlusErrorCodes.SlugDuplicate);
        }
    }

    private async Task<PrepCategory> RequireCategoryAsync(
        Guid categoryId,
        CancellationToken cancellationToken)
    {
        var category = await dbContext.PrepCategories
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CategoryId == categoryId && c.IsActive, cancellationToken)
            ?? throw new AppException(
                "Category not found or inactive.",
                404,
                PrepPlusErrorCodes.CategoryInactive);

        if (category.ParentCategoryId == null)
        {
            throw new AppException(
                "Catalog items must be assigned to a subcategory, not a root category.",
                400,
                PrepPlusErrorCodes.ItemRequiresSubcategory);
        }

        return category;
    }

    private async Task ValidateInstitutionTagAsync(
        Guid categoryId,
        string? institutionTag,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(institutionTag))
        {
            return;
        }

        var rootType = await GetRootCategoryTypeAsync(categoryId, cancellationToken);
        if (rootType != PrepPlusConstants.CategoryTypes.Geographic)
        {
            throw new AppException(
                "Institution tag is only allowed for geographic categories.",
                400,
                PrepPlusErrorCodes.InstitutionTagGeographicOnly);
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

    private async Task EnsureQuizLinkableAsync(Quiz quiz, CancellationToken cancellationToken)
    {
        var isAdminAuthor = await dbContext.UserRoles
            .AsNoTracking()
            .AnyAsync(
                ur => ur.UserId == quiz.CreatedByUserId
                    && (ur.Role.Code == RoleCodes.ContentAdmin
                        || ur.Role.Code == RoleCodes.SuperAdmin),
                cancellationToken);
        if (!isAdminAuthor)
        {
            throw new AppException(
                "Only quizzes created by a content or super admin can be added to Preparación+.",
                400,
                PrepPlusErrorCodes.QuizNotEligible);
        }
    }

    private static void ValidateOffers(IReadOnlyList<UpsertPrepAccessOfferInput> offers)
    {
        if (offers.Count == 0)
        {
            throw new AppException(
                "At least one access offer is required.",
                400,
                PrepPlusErrorCodes.OffersRequired);
        }

        foreach (var offer in offers)
        {
            if (!PrepPlusConstants.AllowedDurationDays.Contains(offer.DurationDays))
            {
                throw new AppException(
                    $"Invalid duration. Allowed: {string.Join(", ", PrepPlusConstants.AllowedDurationDays)}.",
                    400,
                    PrepPlusErrorCodes.InvalidDuration);
            }

            if (!offer.IsFree && offer.PriceAmount < 0)
            {
                throw new AppException("Price cannot be negative.", 400, PrepPlusErrorCodes.PriceNegative);
            }
        }

        if (offers.Select(o => o.DurationDays).Distinct().Count() != offers.Count)
        {
            throw new AppException(
                "Duplicate duration in offers.",
                400,
                PrepPlusErrorCodes.OfferDurationDuplicate);
        }
    }

    private async Task ValidatePublishableAsync(
        PrepCatalogItem entity,
        CancellationToken cancellationToken)
    {
        if (!entity.AccessOffers.Any(o => o.IsActive))
        {
            throw new AppException(
                "At least one active access offer is required to publish.",
                400,
                PrepPlusErrorCodes.ActiveOfferRequiredPublish);
        }

        if (entity.SampleQuestions.Count != PrepPlusConstants.RequiredSampleQuestionCount)
        {
            throw new AppException(
                $"Configure exactly {PrepPlusConstants.RequiredSampleQuestionCount} sample questions before publishing.",
                400,
                PrepPlusErrorCodes.SamplesRequiredPublish,
                new Dictionary<string, object?>
                {
                    ["requiredCount"] = PrepPlusConstants.RequiredSampleQuestionCount,
                });
        }

        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == entity.QuizId, cancellationToken);
        if (questionCount == 0)
        {
            throw new AppException(
                "Linked quiz must have at least one question.",
                400,
                PrepPlusErrorCodes.QuizNoQuestions);
        }

        if (entity.ListingEndsAt.HasValue && entity.ListingStartsAt.HasValue
            && entity.ListingEndsAt <= entity.ListingStartsAt)
        {
            throw new AppException(
                "Listing end must be after listing start.",
                400,
                PrepPlusErrorCodes.ListingEndBeforeStart);
        }
    }

    private async Task<PrepCatalogItemDetailDto> MapDetailAsync(
        PrepCatalogItem item,
        CancellationToken cancellationToken)
    {
        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == item.QuizId, cancellationToken);
        var categoryType = await GetRootCategoryTypeAsync(item.CategoryId, cancellationToken);

        return new PrepCatalogItemDetailDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = item.QuizId,
            QuizTitle = item.Quiz.Title,
            CategoryId = item.CategoryId,
            CategoryName = item.Category.Name,
            CategoryType = categoryType,
            TitleOverride = item.TitleOverride,
            Description = item.Description,
            CoverMediaId = item.CoverMediaId,
            Tags = DeserializeTags(item.TagsJson),
            InstitutionTag = item.InstitutionTag,
            ListingStartsAt = item.ListingStartsAt,
            ListingEndsAt = item.ListingEndsAt,
            IsPublished = item.IsPublished,
            PublishedAt = item.PublishedAt,
            IsDeleted = item.IsDeleted,
            QuestionCount = questionCount,
            Offers = item.AccessOffers
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
            SampleQuestions = item.SampleQuestions
                .OrderBy(s => s.SortOrder)
                .Select(s => new PrepSampleQuestionDto
                {
                    QuestionId = s.QuestionId,
                    SortOrder = s.SortOrder,
                    PromptPreview = Truncate(s.Question.QuestionText, 120),
                })
                .ToList(),
        };
    }

    private static PrepCatalogItemSummaryDto MapSummary(PrepCatalogItem item, int questionCount) => new()
    {
        CatalogItemId = item.CatalogItemId,
        QuizId = item.QuizId,
        CategoryId = item.CategoryId,
        CategoryName = item.Category.Name,
        DisplayTitle = item.TitleOverride ?? item.Quiz.Title,
        IsPublished = item.IsPublished,
        IsDeleted = item.IsDeleted,
        ListingEndsAt = item.ListingEndsAt,
        QuestionCount = questionCount,
        ActiveOfferCount = item.AccessOffers.Count(o => o.IsActive),
        SampleQuestionCount = item.SampleQuestions.Count,
        Tags = DeserializeTags(item.TagsJson),
    };

    private static PrepCategoryDto MapCategory(PrepCategory entity) => new()
    {
        CategoryId = entity.CategoryId,
        ParentCategoryId = entity.ParentCategoryId,
        CategoryType = entity.CategoryType,
        Slug = entity.Slug,
        Name = entity.Name,
        Description = entity.Description,
        CountryCode = entity.CountryCode,
        IconKey = entity.IconKey,
        SortOrder = entity.SortOrder,
        IsActive = entity.IsActive,
    };

    private static PrepCategoryDto MapCategoryTree(PrepCategory node, List<PrepCategory> all)
    {
        var dto = MapCategory(node);
        var children = all
            .Where(c => c.ParentCategoryId == node.CategoryId)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .Select(c => MapCategoryTree(c, all))
            .ToList();
        return new PrepCategoryDto
        {
            CategoryId = dto.CategoryId,
            ParentCategoryId = dto.ParentCategoryId,
            CategoryType = dto.CategoryType,
            Slug = dto.Slug,
            Name = dto.Name,
            Description = dto.Description,
            CountryCode = dto.CountryCode,
            IconKey = dto.IconKey,
            SortOrder = dto.SortOrder,
            IsActive = dto.IsActive,
            Children = children,
        };
    }

    private static HashSet<Guid> CollectSubtreeCategoryIds(
        Guid rootId,
        IReadOnlyList<PrepCategory> all)
    {
        var subtree = new HashSet<Guid> { rootId };
        var added = true;
        while (added)
        {
            added = false;
            foreach (var category in all)
            {
                if (category.ParentCategoryId is { } parentId
                    && subtree.Contains(parentId)
                    && subtree.Add(category.CategoryId))
                {
                    added = true;
                }
            }
        }

        return subtree;
    }

    private static string NormalizeSlug(string slug) =>
        slug.Trim().ToLowerInvariant().Replace(' ', '-');

    private static string? SerializeTags(IReadOnlyList<string> tags)
    {
        var cleaned = tags
            .Select(t => t.Trim())
            .Where(t => !string.IsNullOrEmpty(t))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        return cleaned.Count == 0 ? null : JsonSerializer.Serialize(cleaned, JsonOptions);
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

    private static string Truncate(string value, int maxLength) =>
        value.Length <= maxLength ? value : value[..maxLength] + "…";
}
