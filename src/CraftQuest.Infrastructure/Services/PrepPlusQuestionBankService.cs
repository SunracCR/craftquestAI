using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.PrepPlus;
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

        var topics = await dbContext.QuizTopics
            .AsNoTracking()
            .Where(t => t.QuizId == quizId)
            .OrderBy(t => t.SortOrder)
            .ThenBy(t => t.Name)
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
                q.QuizTopicId,
                q.Difficulty,
            })
            .ToListAsync(cancellationToken);

        var sectionCounts = questions
            .Where(q => q.QuizSectionId != null)
            .GroupBy(q => q.QuizSectionId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var topicCounts = questions
            .Where(q => q.QuizTopicId != null)
            .GroupBy(q => q.QuizTopicId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var sectionDtos = sections.Select(s => new PrepQuizSectionDto
        {
            SectionId = s.QuizSectionId,
            Name = s.Name,
            SortOrder = s.SortOrder,
            QuestionCount = sectionCounts.GetValueOrDefault(s.QuizSectionId),
            Topics = topics
                .Where(t => t.QuizSectionId == s.QuizSectionId)
                .Select(t => new PrepQuizTopicDto
                {
                    TopicId = t.QuizTopicId,
                    SectionId = t.QuizSectionId,
                    Name = t.Name,
                    SortOrder = t.SortOrder,
                    QuestionCount = topicCounts.GetValueOrDefault(t.QuizTopicId),
                })
                .ToList(),
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
                TopicId = q.QuizTopicId,
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

        return MapSection(entity, []);
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

        var counts = await BuildSectionTopicCountsAsync(item.QuizId, cancellationToken);
        var topics = await dbContext.QuizTopics
            .AsNoTracking()
            .Where(t => t.QuizSectionId == sectionId)
            .OrderBy(t => t.SortOrder)
            .ThenBy(t => t.Name)
            .ToListAsync(cancellationToken);

        return MapSection(section, topics, counts.SectionCounts, counts.TopicCounts);
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
            question.QuizTopicId = null;
            question.UpdatedAt = DateTime.UtcNow;
        }

        dbContext.QuizSections.Remove(section);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<PrepQuizTopicDto> CreateTopicAsync(
        Guid catalogItemId,
        UpsertPrepQuizTopicRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateSectionName(request.Name);

        var section = await dbContext.QuizSections
            .AsNoTracking()
            .FirstOrDefaultAsync(
                s => s.QuizSectionId == request.SectionId && s.QuizId == item.QuizId,
                cancellationToken)
            ?? throw new AppException("Section not found.", 404);

        var entity = new QuizTopic
        {
            QuizTopicId = Guid.NewGuid(),
            QuizId = item.QuizId,
            QuizSectionId = section.QuizSectionId,
            Name = request.Name.Trim(),
            SortOrder = request.SortOrder,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.QuizTopics.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapTopic(entity, 0);
    }

    public async Task<PrepQuizTopicDto> UpdateTopicAsync(
        Guid catalogItemId,
        Guid topicId,
        UpsertPrepQuizTopicRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateSectionName(request.Name);

        var topic = await dbContext.QuizTopics
            .FirstOrDefaultAsync(t => t.QuizTopicId == topicId && t.QuizId == item.QuizId, cancellationToken)
            ?? throw new AppException("Topic not found.", 404);

        var section = await dbContext.QuizSections
            .AsNoTracking()
            .FirstOrDefaultAsync(
                s => s.QuizSectionId == request.SectionId && s.QuizId == item.QuizId,
                cancellationToken)
            ?? throw new AppException("Section not found.", 404);

        topic.QuizSectionId = section.QuizSectionId;
        topic.Name = request.Name.Trim();
        topic.SortOrder = request.SortOrder;

        var questions = await dbContext.Questions
            .Where(q => q.QuizId == item.QuizId && q.QuizTopicId == topicId)
            .ToListAsync(cancellationToken);

        foreach (var question in questions)
        {
            question.QuizSectionId = section.QuizSectionId;
            question.UpdatedAt = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var count = await dbContext.Questions
            .CountAsync(q => q.QuizId == item.QuizId && q.QuizTopicId == topicId, cancellationToken);

        return MapTopic(topic, count);
    }

    public async Task DeleteTopicAsync(
        Guid catalogItemId,
        Guid topicId,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadCatalogItemAsync(catalogItemId, cancellationToken);

        var topic = await dbContext.QuizTopics
            .FirstOrDefaultAsync(t => t.QuizTopicId == topicId && t.QuizId == item.QuizId, cancellationToken)
            ?? throw new AppException("Topic not found.", 404);

        var questions = await dbContext.Questions
            .Where(q => q.QuizId == item.QuizId && q.QuizTopicId == topicId)
            .ToListAsync(cancellationToken);

        foreach (var question in questions)
        {
            question.QuizTopicId = null;
            question.UpdatedAt = DateTime.UtcNow;
        }

        dbContext.QuizTopics.Remove(topic);
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

        var topics = await dbContext.QuizTopics
            .AsNoTracking()
            .Where(t => t.QuizId == item.QuizId)
            .Select(t => new { t.QuizTopicId, t.QuizSectionId })
            .ToListAsync(cancellationToken);

        var topicMap = topics.ToDictionary(t => t.QuizTopicId, t => t.QuizSectionId);
        var sectionSet = sections.ToHashSet();
        var byId = questions.ToDictionary(q => q.QuestionId);

        foreach (var tag in request.Questions)
        {
            var question = byId[tag.QuestionId];

            if (tag.TopicId.HasValue)
            {
                if (!topicMap.TryGetValue(tag.TopicId.Value, out var topicSectionId))
                {
                    throw new AppException("Topic not found.", 404);
                }

                question.QuizTopicId = tag.TopicId;
                question.QuizSectionId = topicSectionId;
            }
            else if (tag.SectionId.HasValue)
            {
                if (!sectionSet.Contains(tag.SectionId.Value))
                {
                    throw new AppException("Section not found.", 404);
                }

                question.QuizSectionId = tag.SectionId;
                question.QuizTopicId = null;
            }
            else
            {
                question.QuizSectionId = null;
                question.QuizTopicId = null;
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

        if (request.SupportsCustomPractice)
        {
            var taggedCount = await dbContext.Questions
                .CountAsync(
                    q => q.QuizId == item.QuizId && q.QuizSectionId != null,
                    cancellationToken);

            if (taggedCount == 0)
            {
                throw new AppException(
                    "Assign at least one question to a chapter before enabling custom practice.",
                    400);
            }
        }

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
        IReadOnlyList<Guid>? topicIds,
        string? difficulty,
        CancellationToken cancellationToken = default)
    {
        var item = await LoadPublishedCatalogItemAsync(catalogItemId, cancellationToken);
        ValidateDifficulty(difficulty);

        var topicSectionMap = await dbContext.QuizTopics
            .AsNoTracking()
            .Where(t => t.QuizId == item.QuizId)
            .ToDictionaryAsync(t => t.QuizTopicId, t => t.QuizSectionId, cancellationToken);

        var filter = new PrepPlusCustomPracticeFilter
        {
            SectionIds = sectionIds,
            TopicIds = topicIds,
            Difficulty = difficulty,
            RequireTaggedSection = true,
        };

        var count = await filter.Apply(
                dbContext.Questions.AsNoTracking().Where(q => q.QuizId == item.QuizId),
                topicSectionMap)
            .CountAsync(cancellationToken);

        return new PrepPracticePoolDto
        {
            AvailableQuestionCount = count,
            MaxQuestionCount = count,
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

        var topics = await dbContext.QuizTopics
            .AsNoTracking()
            .Where(t => t.QuizId == quizId)
            .OrderBy(t => t.SortOrder)
            .ThenBy(t => t.Name)
            .ToListAsync(cancellationToken);

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId && q.QuizSectionId != null)
            .Select(q => new { q.QuizSectionId, q.QuizTopicId })
            .ToListAsync(cancellationToken);

        var sectionCounts = questions.GroupBy(q => q.QuizSectionId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var topicCounts = questions
            .Where(q => q.QuizTopicId != null)
            .GroupBy(q => q.QuizTopicId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        return sections
            .Where(s => sectionCounts.GetValueOrDefault(s.QuizSectionId) > 0)
            .Select(s => new PrepPracticeSectionPublicDto
            {
                SectionId = s.QuizSectionId,
                Name = s.Name,
                QuestionCount = sectionCounts.GetValueOrDefault(s.QuizSectionId),
                Topics = topics
                    .Where(t => t.QuizSectionId == s.QuizSectionId
                        && topicCounts.GetValueOrDefault(t.QuizTopicId) > 0)
                    .Select(t => new PrepPracticeTopicPublicDto
                    {
                        TopicId = t.QuizTopicId,
                        Name = t.Name,
                        QuestionCount = topicCounts.GetValueOrDefault(t.QuizTopicId),
                    })
                    .ToList(),
            })
            .ToList();
    }

    internal async Task ValidateCustomPracticeStartAsync(
        Guid userId,
        Guid catalogItemId,
        PrepCatalogItem item,
        CancellationToken cancellationToken)
    {
        if (!item.SupportsCustomPractice)
        {
            throw new AppException("Custom practice is not enabled for this item.", 400);
        }

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

    private async Task<(Dictionary<Guid, int> SectionCounts, Dictionary<Guid, int> TopicCounts)> BuildSectionTopicCountsAsync(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId)
            .Select(q => new { q.QuizSectionId, q.QuizTopicId })
            .ToListAsync(cancellationToken);

        return (
            questions.Where(q => q.QuizSectionId != null)
                .GroupBy(q => q.QuizSectionId!.Value)
                .ToDictionary(g => g.Key, g => g.Count()),
            questions.Where(q => q.QuizTopicId != null)
                .GroupBy(q => q.QuizTopicId!.Value)
                .ToDictionary(g => g.Key, g => g.Count()));
    }

    private static PrepQuizSectionDto MapSection(
        QuizSection section,
        IReadOnlyList<QuizTopic> topics,
        Dictionary<Guid, int>? sectionCounts = null,
        Dictionary<Guid, int>? topicCounts = null) => new()
    {
        SectionId = section.QuizSectionId,
        Name = section.Name,
        SortOrder = section.SortOrder,
        QuestionCount = sectionCounts?.GetValueOrDefault(section.QuizSectionId) ?? 0,
        Topics = topics.Select(t => MapTopic(t, topicCounts?.GetValueOrDefault(t.QuizTopicId) ?? 0)).ToList(),
    };

    private static PrepQuizTopicDto MapTopic(QuizTopic topic, int questionCount) => new()
    {
        TopicId = topic.QuizTopicId,
        SectionId = topic.QuizSectionId,
        Name = topic.Name,
        SortOrder = topic.SortOrder,
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
