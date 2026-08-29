using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Practice;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusQuestionBankService(CraftQuestDbContext dbContext) : IPrepPlusQuestionBankService
{
    private static readonly HashSet<string> ValidDifficulties = new(StringComparer.OrdinalIgnoreCase)
    {
        "easy", "medium", "hard",
    };

    public async Task<PrepQuestionBankDto> GetQuestionBankAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        var quizId = item.QuizId;

        var sections = await dbContext.QuizSections
            .AsNoTracking()
            .Where(s => s.QuizId == quizId)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Name)
            .ToListAsync(cancellationToken);

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId)
            .OrderBy(q => q.SortOrder)
            .Select(q => new
            {
                q.QuestionId,
                q.SortOrder,
                q.QuestionText,
                q.QuizSectionId,
                q.Difficulty,
            })
            .ToListAsync(cancellationToken);

        var sectionCounts = questions
            .Where(q => q.QuizSectionId != null)
            .GroupBy(q => q.QuizSectionId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var sectionDtos = sections.Select(s => new PrepQuizSectionDto
        {
            SectionId = s.QuizSectionId,
            Name = s.Name,
            SortOrder = s.SortOrder,
            QuestionCount = sectionCounts.GetValueOrDefault(s.QuizSectionId),
        }).ToList();

        return new PrepQuestionBankDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = quizId,
            SupportsCustomPractice = item.SupportsCustomPractice,
            UntaggedQuestionCount = questions.Count(q => q.QuizSectionId == null),
            Sections = sectionDtos,
            Questions = questions.Select(q => new PrepQuestionBankQuestionDto
            {
                QuestionId = q.QuestionId,
                SortOrder = q.SortOrder,
                PromptPreview = Truncate(q.QuestionText, 160),
                SectionId = q.QuizSectionId,
                Difficulty = q.Difficulty,
            }).ToList(),
        };
    }

    public async Task<PrepQuizSectionDto> CreateSectionAsync(
        Guid catalogItemId,
        UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateSectionName(request.Name);

        var entity = new QuizSection
        {
            QuizSectionId = Guid.NewGuid(),
            QuizId = item.QuizId,
            Name = request.Name.Trim(),
            SortOrder = request.SortOrder,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.QuizSections.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapSection(entity, 0);
    }

    public async Task<PrepQuizSectionDto> UpdateSectionAsync(
        Guid catalogItemId,
        Guid sectionId,
        UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateSectionName(request.Name);

        var section = await dbContext.QuizSections
            .FirstOrDefaultAsync(s => s.QuizSectionId == sectionId && s.QuizId == item.QuizId, cancellationToken)
            ?? throw new AppException("Section not found.", 404);

        section.Name = request.Name.Trim();
        section.SortOrder = request.SortOrder;
        await dbContext.SaveChangesAsync(cancellationToken);

        var count = await dbContext.Questions
            .CountAsync(q => q.QuizId == item.QuizId && q.QuizSectionId == sectionId, cancellationToken);

        return MapSection(section, count);
    }

    public async Task DeleteSectionAsync(
        Guid catalogItemId,
        Guid sectionId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);

        var section = await dbContext.QuizSections
            .FirstOrDefaultAsync(s => s.QuizSectionId == sectionId && s.QuizId == item.QuizId, cancellationToken)
            ?? throw new AppException("Section not found.", 404);

        var questions = await dbContext.Questions
            .Where(q => q.QuizId == item.QuizId && q.QuizSectionId == sectionId)
            .ToListAsync(cancellationToken);

        foreach (var question in questions)
        {
            question.QuizSectionId = null;
            question.UpdatedAt = DateTime.UtcNow;
        }

        dbContext.QuizSections.Remove(section);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task BulkTagQuestionsAsync(
        Guid catalogItemId,
        BulkTagPrepQuestionsRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        if (request.Questions.Count == 0)
        {
            return;
        }

        var questionIds = request.Questions.Select(q => q.QuestionId).ToHashSet();
        var questions = await dbContext.Questions
            .Where(q => q.QuizId == item.QuizId && questionIds.Contains(q.QuestionId))
            .ToListAsync(cancellationToken);

        if (questions.Count != questionIds.Count)
        {
            throw new AppException("One or more questions were not found for this quiz.", 400);
        }

        var sections = await dbContext.QuizSections
            .AsNoTracking()
            .Where(s => s.QuizId == item.QuizId)
            .Select(s => s.QuizSectionId)
            .ToListAsync(cancellationToken);

        var sectionSet = sections.ToHashSet();
        var byId = questions.ToDictionary(q => q.QuestionId);

        foreach (var tag in request.Questions)
        {
            var question = byId[tag.QuestionId];

            if (tag.SectionId.HasValue)
            {
                if (!sectionSet.Contains(tag.SectionId.Value))
                {
                    throw new AppException("Section not found.", 404);
                }

                question.QuizSectionId = tag.SectionId;
            }
            else
            {
                question.QuizSectionId = null;
            }

            if (tag.Difficulty is not null)
            {
                var difficulty = tag.Difficulty.Trim().ToLowerInvariant();
                if (difficulty.Length == 0)
                {
                    question.Difficulty = null;
                }
                else if (!ValidDifficulties.Contains(difficulty))
                {
                    throw new AppException("Invalid difficulty. Use easy, medium, or hard.", 400);
                }
                else
                {
                    question.Difficulty = difficulty;
                }
            }

            question.UpdatedAt = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<PrepCatalogItemDetailDto> SetCustomPracticeAsync(
        Guid catalogItemId,
        SetPrepCustomPracticeRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await dbContext.PrepCatalogItems
            .Include(i => i.Quiz)
            .Include(i => i.Category)
            .Include(i => i.AccessOffers)
            .Include(i => i.SampleQuestions)
                .ThenInclude(s => s.Question)
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404);

        item.SupportsCustomPractice = request.SupportsCustomPractice;
        item.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return await MapAdminDetailAsync(item, cancellationToken);
    }

    public async Task<IReadOnlyList<PrepPracticeSectionPublicDto>> GetPracticeStructureAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedCatalogItemAsync(catalogItemId, cancellationToken);
        return await BuildPracticeStructureAsync(item.QuizId, cancellationToken);
    }

    public async Task<PrepPracticePoolDto> GetPracticePoolAsync(
        Guid catalogItemId,
        IReadOnlyList<Guid>? sectionIds,
        string? difficulty,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateDifficulty(difficulty);

        var filter = BuildFilter(sectionIds, difficulty);
        var questions = await PracticeQuestionLoader.LoadForQuizAsync(
            dbContext,
            item.QuizId,
            filter,
            cancellationToken);

        return new PrepPracticePoolDto
        {
            AvailableQuestionCount = questions.Count,
            MaxQuestionCount = questions.Count,
        };
    }

    internal async Task<IReadOnlyList<PrepPracticeSectionPublicDto>> BuildPracticeStructureAsync(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var sections = await dbContext.QuizSections
            .AsNoTracking()
            .Where(s => s.QuizId == quizId)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Name)
            .ToListAsync(cancellationToken);

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId && q.QuizSectionId != null)
            .Select(q => q.QuizSectionId!.Value)
            .ToListAsync(cancellationToken);

        var sectionCounts = questions
            .GroupBy(id => id)
            .ToDictionary(g => g.Key, g => g.Count());

        return sections
            .Where(s => sectionCounts.GetValueOrDefault(s.QuizSectionId) > 0)
            .Select(s => new PrepPracticeSectionPublicDto
            {
                SectionId = s.QuizSectionId,
                Name = s.Name,
                QuestionCount = sectionCounts.GetValueOrDefault(s.QuizSectionId),
            })
            .ToList();
    }

    internal async Task ValidatePrepPlusPracticeAccessAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var hasAccess = await dbContext.QuizAccesses.AnyAsync(
            a => a.UserId == userId
                && a.PrepCatalogItemId == catalogItemId
                && a.AccessType == "purchase"
                && (a.IsLifetimeAccess || (a.ExpiresAt != null && a.ExpiresAt > now)),
            cancellationToken);

        if (!hasAccess)
        {
            throw new AppException("You do not have Prep+ access for this item.", 403);
        }
    }

    internal static PracticeQuestionLoader.FilterOptions BuildFilter(
        IReadOnlyList<Guid>? sectionIds,
        string? difficulty) => new()
    {
        SectionIds = sectionIds,
        Difficulty = difficulty,
        RequireTaggedSection = sectionIds is { Count: > 0 },
    };

    private async Task<PrepCatalogItem> LoadCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        return await dbContext.PrepCatalogItems
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.CatalogItemId == catalogItemId && !i.IsDeleted, cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404);
    }

    private async Task<PrepCatalogItem> LoadPublishedCatalogItemAsync(
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var item = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .FirstOrDefaultAsync(
                i => i.CatalogItemId == catalogItemId
                    && i.IsPublished
                    && !i.IsDeleted
                    && (i.ListingStartsAt == null || i.ListingStartsAt <= now)
                    && (i.ListingEndsAt == null || i.ListingEndsAt > now),
                cancellationToken)
            ?? throw new AppException("Catalog item not found.", 404);

        return item;
    }

    private static PrepQuizSectionDto MapSection(QuizSection section, int questionCount) => new()
    {
        SectionId = section.QuizSectionId,
        Name = section.Name,
        SortOrder = section.SortOrder,
        QuestionCount = questionCount,
    };

    private static void ValidateSectionName(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new AppException("Name is required.", 400);
        }
    }

    private static void ValidateDifficulty(string? difficulty)
    {
        if (string.IsNullOrWhiteSpace(difficulty))
        {
            return;
        }

        if (!ValidDifficulties.Contains(difficulty.Trim()))
        {
            throw new AppException("Invalid difficulty. Use easy, medium, or hard.", 400);
        }
    }

    private static string Truncate(string value, int maxLength)
    {
        if (value.Length <= maxLength)
        {
            return value;
        }

        return value[..(maxLength - 1)] + "…";
    }

    private async Task<PrepCatalogItemDetailDto> MapAdminDetailAsync(
        PrepCatalogItem item,
        CancellationToken cancellationToken)
    {
        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == item.QuizId, cancellationToken);

        return new PrepCatalogItemDetailDto
        {
            CatalogItemId = item.CatalogItemId,
            QuizId = item.QuizId,
            QuizTitle = item.Quiz.Title,
            CategoryId = item.CategoryId,
            CategoryName = item.Category.Name,
            CategoryType = item.Category.CategoryType,
            TitleOverride = item.TitleOverride,
            Description = item.Description,
            Slug = item.Slug,
            CoverMediaId = item.CoverMediaId,
            Tags = [],
            InstitutionTag = item.InstitutionTag,
            ListingStartsAt = item.ListingStartsAt,
            ListingEndsAt = item.ListingEndsAt,
            IsPublished = item.IsPublished,
            PublishedAt = item.PublishedAt,
            IsDeleted = item.IsDeleted,
            SupportsCustomPractice = item.SupportsCustomPractice,
            QuestionCount = questionCount,
            Offers = item.AccessOffers
                .OrderBy(o => o.IsLifetimeAccess)
                .ThenBy(o => o.DurationDays)
                .Select(o => new PrepAccessOfferDto
                {
                    OfferId = o.OfferId,
                    DurationDays = o.DurationDays,
                    IsLifetimeAccess = o.IsLifetimeAccess,
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
                    PromptPreview = Truncate(s.Question?.QuestionText ?? string.Empty, 120),
                })
                .ToList(),
        };
    }
}
