using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Offline;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Offline;
using CraftQuest.Infrastructure.Services.Practice;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class OfflineQuizService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    IMediaService mediaService,
    IAnalyticsService analyticsService,
    OfflinePackageCryptoService cryptoService,
    IOptions<OfflineOptions> offlineOptions,
    ILogger<OfflineQuizService> logger) : IOfflineQuizService
{
    private const string QuestionImageKey = "QUESTION_IMAGE";

    public async Task<OfflineQuizPackageDto> GetOfflinePackageAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await billingService.EnsureCanDownloadOfflineAsync(userId, cancellationToken);
        var entitlements = await billingService.GetOfflineEntitlementsAsync(userId, cancellationToken);

        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.PublicationStatus != "published")
        {
            throw new AppException("Quiz is not published.", 403);
        }

        await EnsureStandaloneQuizAccessAsync(userId, quiz, cancellationToken);

        var questions = await PracticeQuestionLoader.LoadForQuizAsync(
            dbContext,
            quizId,
            cancellationToken);

        if (questions.Count == 0)
        {
            throw new AppException("Quiz has no questions.", 400);
        }

        var packageKey = cryptoService.GeneratePackageKey();
        var packageKeyBase64 = Convert.ToBase64String(packageKey);
        var maxQuestionUpdated = questions.Max(q => q.UpdatedAt);
        var contentVersion = OfflinePackageCryptoService.ComputeContentVersion(
            quiz.QuizId,
            quiz.UpdatedAt,
            questions.Count,
            maxQuestionUpdated);

        var now = DateTime.UtcNow;
        var expiresAt = now.AddDays(Math.Max(1, offlineOptions.Value.PackageTtlDays));
        var watermark = cryptoService.BuildWatermarkToken(userId, quizId);

        var mediaAssets = new Dictionary<Guid, OfflinePackageMediaAssetDto>();
        var packageQuestions = new List<OfflinePackageQuestionDto>();

        foreach (var question in questions.OrderBy(q => q.SortOrder))
        {
            var allOptions = question.AnswerOptions.Where(o => o.IsActive).ToList();
            var stemOption = allOptions.FirstOrDefault(o =>
                string.Equals(o.StableKey, QuestionImageKey, StringComparison.OrdinalIgnoreCase));
            var selectableOptions = allOptions
                .Where(o => !string.Equals(o.StableKey, QuestionImageKey, StringComparison.OrdinalIgnoreCase))
                .OrderBy(o => o.DefaultSortOrder)
                .ToList();

            var correctIds = question.CorrectAnswerOptions
                .Select(c => c.AnswerOptionId)
                .ToList();

            var scoringPolicy = AnswerGradingService.ResolveScoringPolicyForQuestionType(
                question.QuestionType.Code,
                question.ScoringPolicy);

            if (stemOption?.MediaAssetId is Guid stemMediaId)
            {
                await AddMediaAssetAsync(mediaAssets, stemMediaId, cancellationToken);
            }

            foreach (var option in selectableOptions)
            {
                if (option.MediaAssetId is Guid mediaId)
                {
                    await AddMediaAssetAsync(mediaAssets, mediaId, cancellationToken);
                }
            }

            packageQuestions.Add(new OfflinePackageQuestionDto
            {
                QuestionId = question.QuestionId,
                SortOrder = question.SortOrder,
                QuestionText = question.QuestionText,
                QuestionType = question.QuestionType.Code,
                Points = question.Points,
                RandomizeAnswerOptions = question.RandomizeAnswerOptions,
                ScoringPolicy = scoringPolicy,
                SupportsMultipleCorrectAnswers = question.QuestionType.SupportsMultipleCorrectAnswers,
                QuestionMediaAssetId = stemOption?.MediaAssetId,
                CorrectAnswerBlob = cryptoService.EncryptCorrectAnswers(packageKey, correctIds),
                AnswerOptions = allOptions
                    .Select(o => new OfflinePackageAnswerOptionDto
                    {
                        AnswerOptionId = o.AnswerOptionId,
                        StableKey = o.StableKey,
                        DefaultSortOrder = o.DefaultSortOrder,
                        AnswerText = o.AnswerText,
                        MediaAssetId = o.MediaAssetId,
                    })
                    .ToList(),
            });
        }

        logger.LogInformation(
            "Offline package generated userId={UserId} quizId={QuizId} questions={QuestionCount} media={MediaCount} watermark={Watermark}",
            userId,
            quizId,
            packageQuestions.Count,
            mediaAssets.Count,
            watermark);

        return new OfflineQuizPackageDto
        {
            QuizId = quiz.QuizId,
            Title = quiz.Title,
            Description = quiz.Description,
            ContentVersion = contentVersion,
            GeneratedAt = now,
            ExpiresAt = expiresAt,
            PackageKeyBase64 = packageKeyBase64,
            RandomizeQuestions = quiz.RandomizeQuestions,
            DefaultRandomizeAnswerOptions = quiz.DefaultRandomizeAnswerOptions,
            WatermarkToken = watermark,
            Questions = packageQuestions,
            MediaAssets = mediaAssets.Values.OrderBy(m => m.MediaAssetId).ToList(),
            Entitlements = entitlements,
        };
    }

    public async Task<OfflineSyncResultDto> SyncOfflineSessionAsync(
        Guid userId,
        OfflineSyncRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.ClientSessionId == Guid.Empty)
        {
            throw new AppException("ClientSessionId is required.", 400);
        }

        var existing = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.QuestionSnapshots)
            .FirstOrDefaultAsync(
                s => s.ClientSessionId == request.ClientSessionId
                    && s.StudentUserId == userId,
                cancellationToken);

        if (existing is not null && existing.Status == "finished")
        {
            return await BuildExistingSyncResultAsync(userId, existing, cancellationToken);
        }

        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == request.QuizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        await EnsureStandaloneQuizAccessAsync(userId, quiz, cancellationToken);

        var questions = await PracticeQuestionLoader.LoadForQuizAsync(
            dbContext,
            request.QuizId,
            cancellationToken);

        var maxQuestionUpdated = questions.Count > 0 ? questions.Max(q => q.UpdatedAt) : null;
        var currentContentVersion = OfflinePackageCryptoService.ComputeContentVersion(
            quiz.QuizId,
            quiz.UpdatedAt,
            questions.Count,
            maxQuestionUpdated);

        var contentChanged = !string.Equals(
            request.ContentVersion,
            currentContentVersion,
            StringComparison.OrdinalIgnoreCase);

        var session = new PracticeSession
        {
            PracticeSessionId = Guid.NewGuid(),
            ClientSessionId = request.ClientSessionId,
            StudentUserId = userId,
            QuizId = request.QuizId,
            StartedAt = request.StartedAt.ToUniversalTime(),
            FinishedAt = request.FinishedAt.ToUniversalTime(),
            DurationSeconds = Math.Max(
                0,
                (int)(request.FinishedAt.ToUniversalTime() - request.StartedAt.ToUniversalTime()).TotalSeconds),
            Status = "finished",
            RandomizationStrategy = "client_offline",
            ShowElapsedTimer = request.ShowElapsedTimer,
            LastActivityAt = request.FinishedAt.ToUniversalTime(),
            CreatedAt = DateTime.UtcNow,
            ScorePossible = questions.Sum(q => q.Points),
        };

        PracticeSessionSnapshotBuilder.PopulateQuestionSnapshots(session, questions);
        await PracticeSnapshotBulkInserter.InsertAsync(dbContext, session, cancellationToken: cancellationToken);

        var answersByQuestion = request.Answers
            .GroupBy(a => a.QuestionId)
            .ToDictionary(g => g.Key, g => g.Last());

        var voidedCount = 0;
        var loadedSession = await dbContext.PracticeSessions
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstAsync(s => s.PracticeSessionId == session.PracticeSessionId, cancellationToken);

        foreach (var snapshot in loadedSession.QuestionSnapshots)
        {
            if (contentChanged
                || !answersByQuestion.TryGetValue(snapshot.QuestionId, out var answer))
            {
                snapshot.AnswerStatus = "omitted";
                snapshot.IsCorrect = null;
                snapshot.PointsAwarded = 0;
                if (contentChanged && answersByQuestion.ContainsKey(snapshot.QuestionId))
                {
                    voidedCount++;
                }

                continue;
            }

            var supportsMultiple = await dbContext.QuestionTypes
                .AsNoTracking()
                .Where(t => t.Code == snapshot.QuestionTypeCodeSnapshot)
                .Select(t => t.SupportsMultipleCorrectAnswers)
                .FirstOrDefaultAsync(cancellationToken);

            var scoringPolicy = await dbContext.Questions
                .AsNoTracking()
                .Where(q => q.QuestionId == snapshot.QuestionId)
                .Select(q => q.ScoringPolicy)
                .FirstOrDefaultAsync(cancellationToken) ?? "strict";

            if (supportsMultiple)
            {
                scoringPolicy = AnswerGradingService.PartialScoringPolicy;
            }

            var selectedIds = PracticeAnswerSelectionWriter.NormalizeSelectedIds(
                answer.SelectedAnswerOptionIds,
                supportsMultiple);

            if (selectedIds.Count == 0)
            {
                snapshot.AnswerStatus = "omitted";
                snapshot.IsCorrect = null;
                snapshot.PointsAwarded = 0;
                continue;
            }

            var validOptionIds = snapshot.AnswerOptionSnapshots
                .Select(a => a.AnswerOptionId)
                .ToHashSet();

            if (selectedIds.Any(id => !validOptionIds.Contains(id)))
            {
                voidedCount++;
                snapshot.AnswerStatus = "omitted";
                snapshot.IsCorrect = null;
                snapshot.PointsAwarded = 0;
                continue;
            }

            var correctIds = snapshot.AnswerOptionSnapshots
                .Where(a => a.IsCorrectSnapshot)
                .Select(a => a.AnswerOptionId)
                .ToHashSet();

            var grading = AnswerGradingService.GradeAnswer(
                selectedIds.ToHashSet(),
                correctIds,
                supportsMultiple,
                scoringPolicy,
                snapshot.PointsPossible);

            PracticeAnswerSelectionWriter.ApplySelection(
                snapshot,
                selectedIds,
                supportsMultiple,
                answer.AnsweredAt?.ToUniversalTime() ?? request.FinishedAt.ToUniversalTime());

            snapshot.AnswerStatus = "answered";
            snapshot.IsCorrect = grading.IsFullyCorrect;
            snapshot.PointsAwarded = grading.PointsAwarded;
            snapshot.SubmittedAt = answer.AnsweredAt?.ToUniversalTime() ?? request.FinishedAt.ToUniversalTime();
            snapshot.TimeSpentSeconds = answer.TimeSpentSeconds;
        }

        ApplyPartialSessionScoring(loadedSession);
        await analyticsService.RecordFinishedPracticeSessionAsync(loadedSession, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        var sessionResult = await BuildSessionResultAsync(userId, loadedSession, cancellationToken);
        var scoreAdjusted = request.LocalScoreObtained.HasValue
            && request.LocalScoreObtained.Value != sessionResult.ScoreObtained;

        logger.LogInformation(
            "Offline session synced userId={UserId} clientSessionId={ClientSessionId} voided={VoidedCount} scoreAdjusted={ScoreAdjusted}",
            userId,
            request.ClientSessionId,
            voidedCount,
            scoreAdjusted);

        return new OfflineSyncResultDto
        {
            SessionResult = sessionResult,
            VoidedQuestionCount = voidedCount,
            ScoreAdjusted = scoreAdjusted,
        };
    }

    private async Task EnsureStandaloneQuizAccessAsync(
        Guid userId,
        Quiz quiz,
        CancellationToken cancellationToken)
    {
        if (quiz.CreatedByUserId == userId || quiz.Visibility == "public")
        {
            return;
        }

        var now = DateTime.UtcNow;
        var hasAccess = await dbContext.QuizAccesses.AnyAsync(
            a => a.UserId == userId
                && a.QuizId == quiz.QuizId
                && (
                    (a.AccessType == "redeemed"
                        && a.AssignmentId == null
                        && a.ClassId == null)
                    || (a.AccessType == "purchase"
                        && (a.IsLifetimeAccess
                            || (a.ExpiresAt != null && a.ExpiresAt > now)))),
            cancellationToken);

        if (!hasAccess)
        {
            throw new AppException(
                "You do not have access to download this quiz for offline use.",
                403,
                "OFFLINE_QUIZ_ACCESS_DENIED");
        }
    }

    private async Task AddMediaAssetAsync(
        Dictionary<Guid, OfflinePackageMediaAssetDto> mediaAssets,
        Guid mediaAssetId,
        CancellationToken cancellationToken)
    {
        if (mediaAssets.ContainsKey(mediaAssetId))
        {
            return;
        }

        var asset = await dbContext.MediaAssets
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.MediaAssetId == mediaAssetId && m.Status == "active", cancellationToken);

        mediaAssets[mediaAssetId] = new OfflinePackageMediaAssetDto
        {
            MediaAssetId = mediaAssetId,
            DownloadUrl = mediaService.BuildPublicUrl(mediaAssetId),
            ContentType = asset?.ContentType,
            FileSizeBytes = asset?.FileSizeBytes,
        };
    }

    private async Task<OfflineSyncResultDto> BuildExistingSyncResultAsync(
        Guid userId,
        PracticeSession session,
        CancellationToken cancellationToken)
    {
        var sessionResult = await BuildSessionResultAsync(userId, session, cancellationToken);
        return new OfflineSyncResultDto
        {
            SessionResult = sessionResult,
            VoidedQuestionCount = 0,
            ScoreAdjusted = false,
        };
    }

    private async Task<PracticeSessionResultDto> BuildSessionResultAsync(
        Guid userId,
        PracticeSession session,
        CancellationToken cancellationToken)
    {
        var percentage = session.ScorePossible > 0
            ? Math.Round(session.ScoreObtained / session.ScorePossible * 100, 2)
            : 0;

        var questionsToReview = session.QuestionSnapshots
            .Where(q => q.AnswerStatus != "answered" || q.IsCorrect != true)
            .OrderBy(q => q.DisplayOrder)
            .Take(3)
            .Select(q => new PracticeWeakQuestionDto
            {
                PracticeQuestionSnapshotId = q.PracticeQuestionSnapshotId,
                QuestionId = q.QuestionId,
                QuestionText = q.QuestionTextSnapshot,
                DisplayOrder = q.DisplayOrder,
            })
            .ToList();

        var previousQuery = dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.StudentUserId == userId
                && ps.QuizId == session.QuizId
                && ps.Status == "finished"
                && ps.PracticeSessionId != session.PracticeSessionId
                && ps.AssignmentId == null
                && ps.FinishedAt < session.FinishedAt);

        var previous = await previousQuery
            .OrderByDescending(ps => ps.FinishedAt)
            .Select(ps => new { ps.ScoreObtained, ps.ScorePossible })
            .FirstOrDefaultAsync(cancellationToken);

        decimal? scoreTrend = null;
        if (previous is not null && previous.ScorePossible > 0)
        {
            var prevPct = previous.ScoreObtained / previous.ScorePossible * 100;
            scoreTrend = Math.Round(percentage - prevPct, 2);
        }

        return new PracticeSessionResultDto
        {
            PracticeSessionId = session.PracticeSessionId,
            ScoreObtained = session.ScoreObtained,
            ScorePossible = session.ScorePossible,
            Percentage = percentage,
            CorrectAnswers = session.CorrectAnswers,
            IncorrectAnswers = session.IncorrectAnswers,
            OmittedAnswers = session.OmittedAnswers,
            CanViewDetailedReview = true,
            ScoreTrendVsPrevious = scoreTrend,
            QuestionsToReview = questionsToReview,
        };
    }

    private static void ApplyPartialSessionScoring(PracticeSession session)
    {
        var correct = 0;
        var incorrect = 0;
        var omitted = 0;
        decimal scoreObtained = 0;

        foreach (var question in session.QuestionSnapshots)
        {
            switch (question.AnswerStatus)
            {
                case "answered":
                    scoreObtained += question.PointsAwarded;
                    if (question.IsCorrect == true)
                    {
                        correct++;
                    }
                    else
                    {
                        incorrect++;
                    }

                    break;
                default:
                    omitted++;
                    question.AnswerStatus = "omitted";
                    break;
            }
        }

        session.ScoreObtained = scoreObtained;
        session.CorrectAnswers = correct;
        session.IncorrectAnswers = incorrect;
        session.OmittedAnswers = omitted;
    }
}
