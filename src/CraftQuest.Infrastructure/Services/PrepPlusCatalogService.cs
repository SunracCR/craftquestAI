using System.Text.Json;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services;
using CraftQuest.Application.Services.PrepPlus;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.PrepPlus;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusCatalogService(
    CraftQuestDbContext dbContext,
    IPrepPlusAccessService prepPlusAccessService,
    IMediaService mediaService,
    IOptions<PracticeOptions> practiceOptions,
    IOptions<JoinLinkOptions> joinLinkOptions,
    ILogger<PrepPlusCatalogService> logger) : IPrepPlusCatalogService
{
    private readonly JoinLinkOptions _joinLinkOptions = joinLinkOptions.Value;
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    private static readonly HashSet<string> ValidPriceFilters = ["all", "free", "paid"];
    private static readonly HashSet<string> ValidUserAccessFilters = ["all", "none", "active", "expired"];

    public async Task<IReadOnlyList<PrepCategoryPublicDto>> GetPublicCategoryTreeAsync(
        CancellationToken cancellationToken = default)
    {
        var timing = new PrepPlusQueryTiming(
            logger,
            practiceOptions.Value.LogStartSessionTiming);

        Dictionary<Guid, int> publishedCounts;
        using (timing.Phase("publishedCounts"))
        {
            publishedCounts = await dbContext.PrepCatalogItems
                .AsNoTracking()
                .Where(i => i.IsPublished && !i.IsDeleted)
                .GroupBy(i => i.CategoryId)
                .Select(g => new { CategoryId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CategoryId, x => x.Count, cancellationToken);
        }

        List<PrepCategory> all;
        using (timing.Phase("loadCategories"))
        {
            all = await dbContext.PrepCategories
                .AsNoTracking()
                .Where(c => c.IsActive)
                .OrderBy(c => c.SortOrder)
                .ThenBy(c => c.Name)
                .ToListAsync(cancellationToken);
        }

        List<PrepCategory> roots;
        using (timing.Phase("mapTree"))
        {
            roots = all.Where(c => c.ParentCategoryId == null).ToList();
        }

        var result = roots.Select(r => MapPublicCategoryTree(r, all, publishedCounts)).ToList();
        timing.LogSummary("GetPublicCategoryTree", $"roots={result.Count}");
        return result;
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

        query = ApplyUserAccessFilter(query, userId, accessFilter, now);

        var items = await query
            .OrderBy(i => i.TitleOverride ?? i.Quiz.Title)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        if (items.Count == 0)
        {
            return [];
        }

        var catalogItemIds = items.Select(i => i.CatalogItemId).ToList();
        var accessByItem = await LoadPurchaseAccessByCatalogItemAsync(
            userId,
            catalogItemIds,
            cancellationToken);

        var quizIds = items.Select(i => i.QuizId).Distinct().ToList();
        var questionCounts = await dbContext.Questions
            .AsNoTracking()
            .Where(q => quizIds.Contains(q.QuizId))
            .GroupBy(q => q.QuizId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);

        return items
            .Select(i =>
            {
                accessByItem.TryGetValue(i.CatalogItemId, out var access);
                var state = ResolveAccessState(access, now);
                return MapBrowseItem(i, questionCounts.GetValueOrDefault(i.QuizId), state, access, now);
            })
            .ToList();
    }

    private IQueryable<PrepCatalogItem> ApplyUserAccessFilter(
        IQueryable<PrepCatalogItem> query,
        Guid userId,
        string accessFilter,
        DateTime now) =>
        accessFilter switch
        {
            "active" => query.Where(i =>
                dbContext.QuizAccesses.Any(a =>
                    a.UserId == userId
                    && a.AccessType == "purchase"
                    && a.PrepCatalogItemId == i.CatalogItemId
                    && a.ExpiresAt > now)),
            "expired" => query.Where(i =>
                dbContext.QuizAccesses.Any(a =>
                    a.UserId == userId
                    && a.AccessType == "purchase"
                    && a.PrepCatalogItemId == i.CatalogItemId
                    && a.ExpiresAt != null
                    && a.ExpiresAt <= now)),
            "none" => query.Where(i =>
                !dbContext.QuizAccesses.Any(a =>
                    a.UserId == userId
                    && a.AccessType == "purchase"
                    && a.PrepCatalogItemId == i.CatalogItemId)),
            _ => query,
        };

    public async Task<PrepCatalogItemPublicDetailDto> GetPublicItemAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedItemAsync(catalogItemId, cancellationToken);
        var now = DateTime.UtcNow;
        var access = await GetPurchaseAccessAsync(userId, item.CatalogItemId, item.QuizId, cancellationToken);
        var questionCount = await dbContext.Questions
            .AsNoTracking()
            .CountAsync(q => q.QuizId == item.QuizId, cancellationToken);
        var rootType = await ResolveRootCategoryTypeAsync(item.Category, cancellationToken);
        var state = ResolveAccessState(access, now);

        return new PrepCatalogItemPublicDetailDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = item.QuizId,
            Slug = item.Slug,
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
            .Include(q => q.CorrectAnswerOptions)
            .Include(q => q.Justification!)
                .ThenInclude(j => j.Sources)
            .Where(q => samples.Contains(q.QuestionId))
            .ToListAsync(cancellationToken);

        var orderedQuestions = samples
            .Select(id => questions.FirstOrDefault(q => q.QuestionId == id))
            .Where(q => q is not null)
            .Cast<Question>()
            .ToList();

        return new PrepPreviewDto
        {
            CatalogItemId = catalogItemId,
            SampleQuestions = orderedQuestions.Select(MapStudentQuestion).ToList(),
            FinishPackage = PrepPreviewReviewMapper.MapFinishPackage(
                item.QuizId,
                orderedQuestions,
                mediaService),
        };
    }

    public async Task<PrepPreviewFinishResultDto> FinishPreviewAsync(
        Guid catalogItemId,
        PrepPreviewFinishRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedItemAsync(catalogItemId, cancellationToken);

        var sampleQuestionIds = await dbContext.PrepSampleQuestions
            .AsNoTracking()
            .Where(s => s.CatalogItemId == catalogItemId)
            .OrderBy(s => s.SortOrder)
            .Select(s => s.QuestionId)
            .ToListAsync(cancellationToken);

        if (sampleQuestionIds.Count == 0)
        {
            throw new AppException(
                "Preview is not available for this item.",
                404,
                PrepPlusErrorCodes.PreviewNotAvailable);
        }

        var answersByQuestion = (request.Answers ?? [])
            .GroupBy(a => a.QuestionId)
            .ToDictionary(g => g.Key, g => g.Last());

        foreach (var questionId in answersByQuestion.Keys)
        {
            if (!sampleQuestionIds.Contains(questionId))
            {
                throw new AppException(
                    "One or more question ids are not part of this preview.",
                    400,
                    PrepPlusErrorCodes.PreviewInvalidQuestion);
            }
        }

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Include(q => q.QuestionType)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .Include(q => q.Justification!)
                .ThenInclude(j => j.Sources)
            .Where(q => sampleQuestionIds.Contains(q.QuestionId))
            .ToListAsync(cancellationToken);

        var orderedQuestions = sampleQuestionIds
            .Select(id => questions.FirstOrDefault(q => q.QuestionId == id))
            .Where(q => q is not null)
            .Cast<Question>()
            .ToList();

        if (orderedQuestions.Count != sampleQuestionIds.Count)
        {
            throw new AppException(
                "Preview sample questions are incomplete.",
                500,
                PrepPlusErrorCodes.PreviewNotAvailable);
        }

        var correctCount = 0;
        var incorrectCount = 0;
        var omittedCount = 0;
        decimal scoreObtained = 0;
        decimal scorePossible = 0;
        var reviewQuestions = new List<TeacherPracticeQuestionReviewDto>();

        for (var index = 0; index < orderedQuestions.Count; index++)
        {
            var question = orderedQuestions[index];
            scorePossible += question.Points;

            var validOptionIds = question.AnswerOptions
                .Where(o => o.IsActive)
                .Select(o => o.AnswerOptionId)
                .ToHashSet();

            var selectedIds = answersByQuestion.TryGetValue(question.QuestionId, out var submission)
                ? submission.SelectedAnswerOptionIds
                    .Where(id => id != Guid.Empty)
                    .Distinct()
                    .ToList()
                : [];

            foreach (var selectedId in selectedIds)
            {
                if (!validOptionIds.Contains(selectedId))
                {
                    throw new AppException(
                        "Invalid answer option id for preview question.",
                        400,
                        PrepPlusErrorCodes.PreviewInvalidAnswerOption);
                }
            }

            var supportsMultiple = question.QuestionType.SupportsMultipleCorrectAnswers;
            var correctIds = question.CorrectAnswerOptions
                .Select(c => c.AnswerOptionId)
                .ToHashSet();

            var scoringPolicy = AnswerGradingService.ResolveScoringPolicyForQuestionType(
                question.QuestionType.Code,
                question.ScoringPolicy);

            string answerStatus;
            bool? isCorrect;
            decimal pointsAwarded;

            if (selectedIds.Count == 0)
            {
                answerStatus = "omitted";
                isCorrect = null;
                pointsAwarded = 0;
                omittedCount++;
            }
            else
            {
                answerStatus = "answered";
                var grading = AnswerGradingService.GradeAnswer(
                    selectedIds.ToHashSet(),
                    correctIds,
                    supportsMultiple,
                    scoringPolicy,
                    question.Points);

                pointsAwarded = grading.PointsAwarded;
                isCorrect = grading.IsFullyCorrect;
                scoreObtained += pointsAwarded;

                if (grading.IsFullyCorrect)
                {
                    correctCount++;
                }
                else
                {
                    incorrectCount++;
                }
            }

            reviewQuestions.Add(
                PrepPreviewReviewMapper.MapQuestion(
                    question,
                    index,
                    selectedIds.ToHashSet(),
                    isCorrect,
                    pointsAwarded,
                    answerStatus,
                    mediaService));
        }

        var percentage = scorePossible > 0
            ? Math.Round(scoreObtained / scorePossible * 100, 2)
            : 0;

        var review = new TeacherPracticeReviewDto
        {
            PracticeSessionId = catalogItemId,
            QuizId = item.QuizId,
            Status = "finished",
            ScoreObtained = scoreObtained,
            ScorePossible = scorePossible,
            FinishedAt = DateTime.UtcNow,
            Student = new TeacherStudentDto
            {
                UserId = Guid.Empty,
                DisplayName = null,
            },
            Questions = reviewQuestions,
            RevealCorrectAnswers = true,
        };

        return new PrepPreviewFinishResultDto
        {
            CatalogItemId = catalogItemId,
            ScoreObtained = scoreObtained,
            ScorePossible = scorePossible,
            Percentage = percentage,
            CorrectAnswers = correctCount,
            IncorrectAnswers = incorrectCount,
            OmittedAnswers = omittedCount,
            Review = review,
        };
    }

    public async Task<PrepMyAccessesDto> GetMyAccessesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var timing = new PrepPlusQueryTiming(
            logger,
            practiceOptions.Value.LogStartSessionTiming);

        var now = DateTime.UtcNow;
        List<QuizAccess> accesses;
        using (timing.Phase("loadAccesses"))
        {
            accesses = await dbContext.QuizAccesses
                .AsNoTracking()
                .Where(a => a.UserId == userId && a.AccessType == "purchase" && a.PrepCatalogItemId != null)
                .OrderByDescending(a => a.GrantedAt)
                .ToListAsync(cancellationToken);
        }

        if (accesses.Count == 0)
        {
            timing.LogSummary("GetMyAccesses", "accessCount=0");
            return new PrepMyAccessesDto { Active = [], Expired = [] };
        }

        var catalogItemIds = accesses
            .Select(a => a.PrepCatalogItemId!.Value)
            .Distinct()
            .ToList();

        Dictionary<Guid, PrepCatalogItem> catalogItems;
        using (timing.Phase("loadCatalogItems"))
        {
            catalogItems = await dbContext.PrepCatalogItems
                .AsNoTracking()
                .Include(i => i.Quiz)
                .Where(i => catalogItemIds.Contains(i.CatalogItemId))
                .ToDictionaryAsync(i => i.CatalogItemId, cancellationToken);
        }

        var quizIds = catalogItems.Values.Select(i => i.QuizId).Distinct().ToList();
        Dictionary<Guid, int> questionCounts;
        using (timing.Phase("questionCounts"))
        {
            questionCounts = await dbContext.Questions
                .AsNoTracking()
                .Where(q => quizIds.Contains(q.QuizId))
                .GroupBy(q => q.QuizId)
                .Select(g => new { g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);
        }

        var active = new List<PrepMyAccessItemDto>();
        var expired = new List<PrepMyAccessItemDto>();

        using (timing.Phase("mapAccesses"))
        {
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
        }

        timing.LogSummary("GetMyAccesses", $"accessCount={accesses.Count}");
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

    public async Task<PrepPublicPreviewDto?> GetPublicPreviewBySlugAsync(
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

        var questionCount = await dbContext.Questions
            .AsNoTracking()
            .CountAsync(q => q.QuizId == item.QuizId, cancellationToken);
        var rootType = await ResolveRootCategoryTypeAsync(item.Category, cancellationToken);
        var activeOffers = item.AccessOffers.Where(o => o.IsActive).ToList();
        var paidOffers = activeOffers.Where(o => !o.IsFree && o.PriceAmount > 0).ToList();
        var bestOffer = activeOffers.OrderBy(o => o.DurationDays).FirstOrDefault();

        return new PrepPublicPreviewDto
        {
            CatalogItemId = item.CatalogItemId,
            Slug = normalizedSlug,
            Title = item.TitleOverride ?? item.Quiz.Title,
            Description = item.Description ?? item.Quiz.Description,
            CategoryName = item.Category.Name,
            RootCategoryType = rootType,
            QuestionCount = questionCount,
            HasFreeOffer = activeOffers.Any(o => o.IsFree),
            ReferralRewardsEligible = paidOffers.Count > 0,
            LowestPaidPrice = paidOffers.Count == 0 ? null : paidOffers.Min(o => o.PriceAmount),
            CurrencyCode = paidOffers.FirstOrDefault()?.CurrencyCode ?? bestOffer?.CurrencyCode,
            BestOfferDurationDays = bestOffer?.DurationDays,
            CoverMediaUrl = item.CoverMediaId is not null && !string.IsNullOrWhiteSpace(item.Slug)
                ? PrepReferralLinkUrlBuilder.BuildPublicShareImageUrl(_joinLinkOptions, item.Slug)
                : null,
        };
    }

    public async Task<PrepCatalogItemSlugDto> ResolveCatalogItemIdBySlugAsync(
        string slug,
        CancellationToken cancellationToken = default)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var item = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .FirstOrDefaultAsync(
                i => i.Slug == normalizedSlug && i.IsPublished && !i.IsDeleted,
                cancellationToken)
            ?? throw new AppException(
                "Catalog item not found.",
                404,
                PrepPlusErrorCodes.CatalogItemNotFound);

        return new PrepCatalogItemSlugDto
        {
            CatalogItemId = item.CatalogItemId,
            Slug = normalizedSlug,
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

    private async Task<string> ResolveRootCategoryTypeAsync(
        PrepCategory category,
        CancellationToken cancellationToken)
    {
        if (!category.ParentCategoryId.HasValue)
        {
            return category.CategoryType;
        }

        var parent = await dbContext.PrepCategories
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CategoryId == category.ParentCategoryId.Value, cancellationToken)
            ?? throw new AppException(
                "Category hierarchy is broken.",
                500,
                PrepPlusErrorCodes.CategoryHierarchyBroken);

        if (!parent.ParentCategoryId.HasValue)
        {
            return parent.CategoryType;
        }

        return await GetRootCategoryTypeFromAncestorAsync(parent, cancellationToken);
    }

    private async Task<string> GetRootCategoryTypeFromAncestorAsync(
        PrepCategory current,
        CancellationToken cancellationToken)
    {
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
            Slug = item.Slug,
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
