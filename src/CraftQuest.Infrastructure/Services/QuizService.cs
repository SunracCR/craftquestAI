using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Application.Services;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Practice;
using CraftQuest.Infrastructure.Services.Quizzes;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class QuizService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    IShareCodeService shareCodeService) : IQuizService
{
    private static readonly HashSet<string> ValidVisibilities =
        ["private", "shared_by_code", "class_only", "public", "curated"];

    private static readonly HashSet<string> ValidPublicationStatuses =
        ["draft", "review", "published", "archived"];

    public async Task<IReadOnlyList<QuestionTypeDto>> GetQuestionTypesAsync(
        CancellationToken cancellationToken = default)
    {
        return await dbContext.QuestionTypes
            .AsNoTracking()
            .Where(x => x.IsActive)
            .OrderBy(x => x.QuestionTypeId)
            .Select(x => new QuestionTypeDto
            {
                Code = x.Code,
                Name = x.Name,
                SupportsMultipleCorrectAnswers = x.SupportsMultipleCorrectAnswers,
                SupportsImages = x.SupportsImages,
                RequiresOptions = x.RequiresOptions,
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<QuizDto> CreateQuizAsync(
        Guid userId,
        CreateQuizRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateVisibility(request.Visibility);
        await billingService.EnsureCanCreateQuizAsync(userId, cancellationToken);

        var quiz = new Quiz
        {
            QuizId = Guid.NewGuid(),
            CreatedByUserId = userId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            Visibility = request.Visibility,
            PublicationStatus = "draft",
            DefaultRandomizeAnswerOptions = request.DefaultRandomizeAnswerOptions,
            RandomizeQuestions = request.RandomizeQuestions,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.Quizzes.Add(quiz);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapQuiz(quiz, 0);
    }

    public async Task<IReadOnlyList<QuizDto>> GetMyQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var quizzes = await dbContext.Quizzes
            .AsNoTracking()
            .Where(q => q.CreatedByUserId == userId)
            .OrderByDescending(q => q.CreatedAt)
            .Select(q => new MyQuizSummaryRow
            {
                QuizId = q.QuizId,
                Title = q.Title,
                Description = q.Description,
                PublicationStatus = q.PublicationStatus,
                Visibility = q.Visibility,
                RandomizeQuestions = q.RandomizeQuestions,
                QuestionCount = q.Questions.Count(),
            })
            .ToListAsync(cancellationToken);

        var quizIds = quizzes.Select(x => x.QuizId).ToList();
        var pendingByQuiz = await ResolvePendingAiImportsByQuizAsync(
            userId,
            quizIds,
            cancellationToken);

        return quizzes
            .Select(row =>
            {
                pendingByQuiz.TryGetValue(row.QuizId, out var pending);
                return MapQuiz(row, pending);
            })
            .ToList();
    }

    public async Task<QuizDto> GetQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        var isOwned = quiz.CreatedByUserId == userId;
        if (!isOwned)
        {
            if (!await shareCodeService.HasQuizAccessAsync(userId, quizId, cancellationToken))
            {
                throw new AppException("You do not have access to this quiz.", 403);
            }
        }

        var count = await dbContext.Questions
            .CountAsync(q => q.QuizId == quizId, cancellationToken);

        PendingAiImportInfo? pending = null;
        if (isOwned)
        {
            pending = await ResolvePendingAiImportForQuizAsync(userId, quizId, cancellationToken);
        }

        return MapQuiz(
            quiz,
            count,
            pending?.ImportId,
            pending?.ValidQuestions,
            isOwned);
    }

    public async Task<QuizDto> UpdateQuizAsync(
        Guid userId,
        Guid quizId,
        UpdateQuizRequest request,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        EnsureQuizOwner(quiz, userId);
        await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);

        if (request.Title is not null)
        {
            quiz.Title = request.Title.Trim();
        }

        if (request.Description is not null)
        {
            quiz.Description = request.Description.Trim();
        }

        if (request.Visibility is not null)
        {
            ValidateVisibility(request.Visibility);
            quiz.Visibility = request.Visibility;
        }

        if (request.PublicationStatus is not null)
        {
            if (!ValidPublicationStatuses.Contains(request.PublicationStatus))
            {
                throw new AppException("Invalid publication status.");
            }

            quiz.PublicationStatus = request.PublicationStatus;
        }

        if (request.RandomizeQuestions.HasValue)
        {
            quiz.RandomizeQuestions = request.RandomizeQuestions.Value;
        }

        if (request.DefaultRandomizeAnswerOptions.HasValue)
        {
            quiz.DefaultRandomizeAnswerOptions = request.DefaultRandomizeAnswerOptions.Value;
        }

        quiz.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var count = await dbContext.Questions
            .CountAsync(q => q.QuizId == quizId, cancellationToken);

        return MapQuiz(quiz, count);
    }

    public async Task DeleteQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await GetOwnedQuizAsync(userId, quizId, cancellationToken);
        var now = DateTime.UtcNow;

        if (dbContext.Database.IsRelational())
        {
            var strategy = dbContext.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var transaction =
                    await dbContext.Database.BeginTransactionAsync(cancellationToken);

                await DeleteQuizCoreAsync(quiz, quizId, now, cancellationToken);

                await transaction.CommitAsync(cancellationToken);
            });

            return;
        }

        await DeleteQuizCoreAsync(quiz, quizId, now, cancellationToken);
    }

    private async Task DeleteQuizCoreAsync(
        Quiz quiz,
        Guid quizId,
        DateTime now,
        CancellationToken cancellationToken)
    {
        await PracticeSessionCleanup.DeletePracticeDataForQuizAsync(dbContext, quizId, cancellationToken);

        if (dbContext.Database.IsRelational())
        {
            await dbContext.GuestVisits
                .Where(v => v.QuizId == quizId)
                .ExecuteDeleteAsync(cancellationToken);

            await dbContext.UserQuizPracticePreferences
                .Where(p => p.QuizId == quizId)
                .ExecuteDeleteAsync(cancellationToken);

            await dbContext.Questions
                .IgnoreQueryFilters()
                .Where(q => q.QuizId == quizId)
                .ExecuteUpdateAsync(
                    setters => setters
                        .SetProperty(q => q.DeletedAt, now)
                        .SetProperty(q => q.UpdatedAt, now),
                    cancellationToken);
        }
        else
        {
            var guestVisits = await dbContext.GuestVisits
                .Where(v => v.QuizId == quizId)
                .ToListAsync(cancellationToken);
            dbContext.GuestVisits.RemoveRange(guestVisits);

            var preferences = await dbContext.UserQuizPracticePreferences
                .Where(p => p.QuizId == quizId)
                .ToListAsync(cancellationToken);
            dbContext.UserQuizPracticePreferences.RemoveRange(preferences);

            var questions = await dbContext.Questions
                .IgnoreQueryFilters()
                .Where(q => q.QuizId == quizId)
                .ToListAsync(cancellationToken);

            foreach (var question in questions)
            {
                question.DeletedAt = now;
                question.UpdatedAt = now;
            }
        }

        quiz.DeletedAt = now;
        quiz.UpdatedAt = now;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<QuestionDto> CreateQuestionAsync(
        Guid userId,
        Guid quizId,
        CreateQuestionRequest request,
        CancellationToken cancellationToken = default,
        bool saveChanges = true,
        int? explicitSortOrder = null,
        bool skipBillingChecks = false,
        Quiz? preloadedQuiz = null,
        QuestionType? preloadedQuestionType = null)
    {
        var quiz = preloadedQuiz ?? await GetOwnedQuizAsync(userId, quizId, cancellationToken);
        if (preloadedQuiz is not null)
        {
            EnsureQuizOwner(quiz, userId);
        }

        if (!skipBillingChecks)
        {
            await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);
            await billingService.EnsureCanAddQuestionAsync(userId, quizId, cancellationToken);
        }

        var questionType = preloadedQuestionType is not null
            && string.Equals(preloadedQuestionType.Code, request.QuestionType, StringComparison.OrdinalIgnoreCase)
            && preloadedQuestionType.IsActive
            ? preloadedQuestionType
            : await dbContext.QuestionTypes
                .FirstOrDefaultAsync(t => t.Code == request.QuestionType && t.IsActive, cancellationToken)
                ?? throw new AppException("Invalid question type.");

        ValidateQuestionRequest(request, questionType);

        var sortOrder = explicitSortOrder
            ?? ((await dbContext.Questions
                .Where(q => q.QuizId == quizId)
                .MaxAsync(q => (int?)q.SortOrder, cancellationToken) ?? 0) + 1);

        var questionId = Guid.NewGuid();
        var optionEntities = new List<QuestionAnswerOption>();
        var keyToOptionId = new Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase);

        var order = 0;
        foreach (var option in request.AnswerOptions.OrderBy(o => o.DefaultSortOrder).ThenBy(o => o.ClientKey))
        {
            var stableKey = NormalizeKey(option.ClientKey);
            if (keyToOptionId.ContainsKey(stableKey))
            {
                throw new AppException($"Duplicate answer key '{stableKey}'.");
            }

            var answerOptionId = Guid.NewGuid();
            keyToOptionId[stableKey] = answerOptionId;

            optionEntities.Add(new QuestionAnswerOption
            {
                AnswerOptionId = answerOptionId,
                QuestionId = questionId,
                StableKey = stableKey,
                AnswerText = option.Text?.Trim(),
                MediaAssetId = option.MediaAssetId,
                DefaultSortOrder = option.DefaultSortOrder == 0 ? order : option.DefaultSortOrder,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            });
            order++;
        }

        var correctIds = ResolveCorrectAnswerIds(request.CorrectAnswerKeys, keyToOptionId, questionType);

        var question = new Question
        {
            QuestionId = questionId,
            QuizId = quizId,
            QuizSectionId = request.SectionId,
            QuestionTypeId = questionType.QuestionTypeId,
            QuestionText = request.Text.Trim(),
            Points = request.Points,
            SortOrder = sortOrder,
            RandomizeAnswerOptions = request.RandomizeAnswerOptions,
            ScoringPolicy = AnswerGradingService.ResolveScoringPolicyForQuestionType(
                questionType.Code,
                request.ScoringPolicy),
            ExplanationVisibility = "never",
            IsGeneratedByAi = request.IsGeneratedByAi,
            CreatedByUserId = userId,
            CreatedAt = DateTime.UtcNow,
            AnswerOptions = optionEntities,
            CorrectAnswerOptions = correctIds.Select(id => new QuestionCorrectAnswerOption
            {
                QuestionId = questionId,
                AnswerOptionId = id,
                CreatedAt = DateTime.UtcNow,
            }).ToList(),
        };

        dbContext.Questions.Add(question);
        await QuestionJustificationWriter.ApplyAsync(
            dbContext,
            question,
            request.Justification,
            request.IsGeneratedByAi,
            cancellationToken);

        quiz.UpdatedAt = DateTime.UtcNow;
        if (saveChanges)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return MapQuestion(question, questionType.Code, includeCorrectIds: true);
    }

    public async Task<QuestionDto> UpdateQuestionAsync(
        Guid userId,
        Guid quizId,
        Guid questionId,
        CreateQuestionRequest request,
        CancellationToken cancellationToken = default)
    {
        var quiz = await GetOwnedQuizAsync(userId, quizId, cancellationToken);
        await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);

        var question = await dbContext.Questions
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .Include(q => q.Justification!)
                .ThenInclude(j => j.Sources)
            .FirstOrDefaultAsync(
                q => q.QuestionId == questionId && q.QuizId == quizId,
                cancellationToken)
            ?? throw new AppException("Question not found.", 404);

        var questionType = await dbContext.QuestionTypes
            .FirstOrDefaultAsync(t => t.Code == request.QuestionType && t.IsActive, cancellationToken)
            ?? throw new AppException("Invalid question type.");

        ValidateQuestionRequest(request, questionType);

        var existingByKey = question.AnswerOptions
            .ToDictionary(o => o.StableKey, StringComparer.OrdinalIgnoreCase);

        var requestedKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var keyToOptionId = new Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase);

        var order = 0;
        foreach (var option in request.AnswerOptions.OrderBy(o => o.DefaultSortOrder).ThenBy(o => o.ClientKey))
        {
            var stableKey = NormalizeKey(option.ClientKey);
            if (!requestedKeys.Add(stableKey))
            {
                throw new AppException($"Duplicate answer key '{stableKey}'.");
            }

            var sortOrder = option.DefaultSortOrder == 0 ? order : option.DefaultSortOrder;

            QuestionAnswerOption entity;
            if (existingByKey.TryGetValue(stableKey, out var existing))
            {
                existing.AnswerText = option.Text?.Trim();
                existing.MediaAssetId = option.MediaAssetId;
                existing.DefaultSortOrder = sortOrder;
                existing.IsActive = true;
                existing.UpdatedAt = DateTime.UtcNow;
                entity = existing;
            }
            else
            {
                entity = new QuestionAnswerOption
                {
                    AnswerOptionId = Guid.NewGuid(),
                    QuestionId = questionId,
                    StableKey = stableKey,
                    AnswerText = option.Text?.Trim(),
                    MediaAssetId = option.MediaAssetId,
                    DefaultSortOrder = sortOrder,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                };
                dbContext.QuestionAnswerOptions.Add(entity);
                existingByKey[stableKey] = entity;
            }

            keyToOptionId[stableKey] = entity.AnswerOptionId;
            order++;
        }

        foreach (var existing in question.AnswerOptions)
        {
            if (!requestedKeys.Contains(existing.StableKey) && existing.IsActive)
            {
                existing.IsActive = false;
                existing.UpdatedAt = DateTime.UtcNow;
            }
        }

        question.CorrectAnswerOptions.Clear();

        var correctIds = ResolveCorrectAnswerIds(request.CorrectAnswerKeys, keyToOptionId, questionType);

        question.QuestionTypeId = questionType.QuestionTypeId;
        question.QuestionText = request.Text.Trim();
        question.Points = request.Points;
        question.RandomizeAnswerOptions = request.RandomizeAnswerOptions;
        question.ScoringPolicy = AnswerGradingService.ResolveScoringPolicyForQuestionType(
            questionType.Code,
            request.ScoringPolicy);
        question.ExplanationVisibility = "never";
        question.UpdatedAt = DateTime.UtcNow;

        foreach (var id in correctIds)
        {
            question.CorrectAnswerOptions.Add(new QuestionCorrectAnswerOption
            {
                QuestionId = questionId,
                AnswerOptionId = id,
                CreatedAt = DateTime.UtcNow,
            });
        }

        await QuestionJustificationWriter.ApplyAsync(
            dbContext,
            question,
            request.Justification,
            generatedByAi: false,
            cancellationToken);

        quiz.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        question.QuestionType = questionType;
        return MapQuestion(question, questionType.Code, includeCorrectIds: true);
    }

    public async Task DeleteQuestionAsync(
        Guid userId,
        Guid quizId,
        Guid questionId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await GetOwnedQuizAsync(userId, quizId, cancellationToken);

        var question = await dbContext.Questions
            .FirstOrDefaultAsync(
                q => q.QuestionId == questionId && q.QuizId == quizId,
                cancellationToken)
            ?? throw new AppException("Question not found.", 404);

        var now = DateTime.UtcNow;
        question.DeletedAt = now;
        question.UpdatedAt = now;
        quiz.UpdatedAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<QuestionDto>> GetQuestionsForAuthorAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await GetOwnedQuizAsync(userId, quizId, cancellationToken);

        return await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId)
            .OrderBy(q => q.SortOrder)
            .Select(q => new QuestionDto
            {
                QuestionId = q.QuestionId,
                QuestionType = q.QuestionType.Code,
                Text = q.QuestionText,
                Points = q.Points,
                RandomizeAnswerOptions = q.RandomizeAnswerOptions,
                ExplanationVisibility = q.ExplanationVisibility,
                AnswerOptions = q.AnswerOptions
                    .Where(o => o.IsActive)
                    .OrderBy(o => o.DefaultSortOrder)
                    .Select(o => new AnswerOptionDto
                    {
                        AnswerOptionId = o.AnswerOptionId,
                        StableKey = o.StableKey,
                        Text = o.AnswerText,
                        MediaAssetId = o.MediaAssetId,
                    })
                    .ToList(),
                CorrectAnswerOptionIds = q.CorrectAnswerOptions
                    .Select(c => c.AnswerOptionId)
                    .ToList(),
                Justification = q.Justification == null
                    || q.Justification.JustificationText == null
                    || q.Justification.JustificationText.Trim() == string.Empty
                    ? null
                    : new QuestionJustificationDto
                    {
                        Text = q.Justification.JustificationText,
                        Status = q.Justification.Status,
                        GeneratedByAi = q.Justification.GeneratedByAi,
                        Visibility = q.ExplanationVisibility,
                        Sources = q.Justification.Sources
                            .OrderByDescending(s => s.IsPrimary)
                            .ThenBy(s => s.SourcePageNumber)
                            .Select(s => new QuestionJustificationSourceDto
                            {
                                JustificationSourceId = s.JustificationSourceId,
                                Title = s.SourceTitle,
                                SourceUrl = s.SourceUrl,
                                Provider = s.SourceProvider,
                                Snippet = s.Snippet,
                                PageNumber = s.SourcePageNumber,
                                StudyMaterialId = s.StudyMaterialId,
                                IsPrimary = s.IsPrimary,
                            })
                            .ToList(),
                    },
            })
            .ToListAsync(cancellationToken);
    }

    private async Task<Quiz> GetOwnedQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        EnsureQuizOwner(quiz, userId);
        return quiz;
    }

    private static void EnsureQuizOwner(Quiz quiz, Guid userId)
    {
        if (quiz.CreatedByUserId != userId)
        {
            throw new AppException("You do not have permission to modify this quiz.", 403);
        }
    }

    private static void ValidateVisibility(string visibility)
    {
        if (!ValidVisibilities.Contains(visibility))
        {
            throw new AppException("Invalid visibility value.");
        }
    }

    private static void ValidateQuestionRequest(CreateQuestionRequest request, QuestionType questionType)
    {
        if (request.AnswerOptions.Count < 2 && questionType.RequiresOptions)
        {
            throw new AppException("At least two answer options are required.");
        }

        if (!questionType.SupportsMultipleCorrectAnswers && request.CorrectAnswerKeys.Count != 1)
        {
            throw new AppException("This question type allows only one correct answer.");
        }

        if (questionType.SupportsMultipleCorrectAnswers && request.CorrectAnswerKeys.Count < 1)
        {
            throw new AppException("At least one correct answer key is required.");
        }
    }

    private static List<Guid> ResolveCorrectAnswerIds(
        IEnumerable<string> correctAnswerKeys,
        IReadOnlyDictionary<string, Guid> keyToOptionId,
        QuestionType questionType)
    {
        var ids = new List<Guid>();

        foreach (var key in correctAnswerKeys)
        {
            var normalized = NormalizeKey(key);
            if (!keyToOptionId.TryGetValue(normalized, out var optionId))
            {
                throw new AppException($"Correct answer key '{key}' does not match any answer option.");
            }

            ids.Add(optionId);
        }

        if (!questionType.SupportsMultipleCorrectAnswers && ids.Distinct().Count() != 1)
        {
            throw new AppException("Only one correct answer is allowed for this question type.");
        }

        return ids.Distinct().ToList();
    }

    private static string NormalizeKey(string key) => key.Trim().ToUpperInvariant();

    private async Task<Dictionary<Guid, PendingAiImportInfo>> ResolvePendingAiImportsByQuizAsync(
        Guid userId,
        IReadOnlyList<Guid> quizIds,
        CancellationToken cancellationToken)
    {
        if (quizIds.Count == 0)
        {
            return [];
        }

        var rows = await (
            from j in dbContext.AiJobs.AsNoTracking()
            join b in dbContext.QuestionImportBatches.AsNoTracking()
                on j.QuestionImportBatchId equals b.QuestionImportBatchId
            where j.RequestedByUserId == userId
                && j.TargetQuizId != null
                && quizIds.Contains(j.TargetQuizId.Value)
                && j.JobType == "generate_quiz"
                && j.Status == "completed"
                && b.Status == "ready_for_review"
                && b.QuizId == j.TargetQuizId
            orderby j.CompletedAt descending
            select new PendingAiImportInfo
            {
                QuizId = j.TargetQuizId!.Value,
                ImportId = b.QuestionImportBatchId,
                ValidQuestions = b.ValidRows,
            })
            .ToListAsync(cancellationToken);

        return rows
            .GroupBy(x => x.QuizId)
            .ToDictionary(g => g.Key, g => g.First());
    }

    private async Task<PendingAiImportInfo?> ResolvePendingAiImportForQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var map = await ResolvePendingAiImportsByQuizAsync(
            userId,
            [quizId],
            cancellationToken);
        return map.TryGetValue(quizId, out var pending) ? pending : null;
    }

    private sealed class PendingAiImportInfo
    {
        public required Guid QuizId { get; init; }
        public required Guid ImportId { get; init; }
        public required int ValidQuestions { get; init; }
    }

    private sealed class MyQuizSummaryRow
    {
        public required Guid QuizId { get; init; }
        public required string Title { get; init; }
        public string? Description { get; init; }
        public required string PublicationStatus { get; init; }
        public required string Visibility { get; init; }
        public bool RandomizeQuestions { get; init; }
        public int QuestionCount { get; init; }
    }

    private static QuizDto MapQuiz(
        MyQuizSummaryRow row,
        PendingAiImportInfo? pending = null) => new()
    {
        QuizId = row.QuizId,
        Title = row.Title,
        Description = row.Description,
        PublicationStatus = row.PublicationStatus,
        Visibility = row.Visibility,
        QuestionCount = row.QuestionCount,
        RandomizeQuestions = row.RandomizeQuestions,
        PendingReviewImportId = pending?.ImportId,
        PendingReviewValidQuestions = pending?.ValidQuestions,
        IsOwned = true,
    };

    private static QuizDto MapQuiz(
        Quiz quiz,
        int questionCount,
        Guid? pendingReviewImportId = null,
        int? pendingReviewValidQuestions = null,
        bool isOwned = true) => new()
    {
        QuizId = quiz.QuizId,
        Title = quiz.Title,
        Description = quiz.Description,
        PublicationStatus = quiz.PublicationStatus,
        Visibility = quiz.Visibility,
        QuestionCount = questionCount,
        RandomizeQuestions = quiz.RandomizeQuestions,
        PendingReviewImportId = pendingReviewImportId,
        PendingReviewValidQuestions = pendingReviewValidQuestions,
        IsOwned = isOwned,
    };

    private static QuestionDto MapQuestion(Question question, string typeCode, bool includeCorrectIds) => new()
    {
        QuestionId = question.QuestionId,
        QuestionType = typeCode,
        Text = question.QuestionText,
        Points = question.Points,
        RandomizeAnswerOptions = question.RandomizeAnswerOptions,
        ExplanationVisibility = question.ExplanationVisibility,
        AnswerOptions = MapAnswerOptions(question.AnswerOptions.Where(o => o.IsActive)),
        CorrectAnswerOptionIds = includeCorrectIds
            ? question.CorrectAnswerOptions.Select(c => c.AnswerOptionId).ToList()
            : [],
        Justification = QuestionJustificationMapper.MapDto(question),
    };

    private static IReadOnlyList<AnswerOptionDto> MapAnswerOptions(IEnumerable<QuestionAnswerOption> options) =>
        options
            .OrderBy(o => o.DefaultSortOrder)
            .Select(o => new AnswerOptionDto
            {
                AnswerOptionId = o.AnswerOptionId,
                StableKey = o.StableKey,
                Text = o.AnswerText,
                MediaAssetId = o.MediaAssetId,
            })
            .ToList();
}
