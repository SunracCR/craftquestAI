using System.Security.Cryptography;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Guest;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Application.Services.Teacher;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Practice;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class GuestService(
    CraftQuestDbContext dbContext,
    IMediaService mediaService) : IGuestService
{
    private static readonly TimeSpan VisitTtl = TimeSpan.FromHours(4);
    private const int MaxAttemptsPerVisit = 10;

    public async Task<GuestVisitDto> EnterAsync(
        GuestEnterRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedCode = (request.Code ?? string.Empty).Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(normalizedCode))
        {
            throw new AppException("Share code is required.", 400);
        }

        var shareCode = await dbContext.ShareCodes
            .Include(s => s.Quiz)
            .FirstOrDefaultAsync(s => s.Code == normalizedCode, cancellationToken)
            ?? throw new AppException("Share code not found.", 404);

        if (shareCode.AccessPolicy == "group_only")
        {
            var className = shareCode.ClassId is null
                ? null
                : await dbContext.TeacherClasses
                    .AsNoTracking()
                    .Where(c => c.ClassId == shareCode.ClassId.Value)
                    .Select(c => c.Name)
                    .FirstOrDefaultAsync(cancellationToken);

            var metadata = new Dictionary<string, object?>();
            if (!string.IsNullOrWhiteSpace(className))
            {
                metadata["className"] = className.Trim();
            }

            throw new AppException(
                "This code is only for class members with an account. Sign in to continue.",
                403,
                errorCode: "GROUP_ACCESS_DENIED",
                metadata: metadata);
        }

        // Solo guest_open permite practicar sin cuenta
        if (shareCode.AccessPolicy != "guest_open")
        {
            throw new AppException(
                "This code requires a registered account. Create a free account to continue.",
                400,
                errorCode: "GUEST_NOT_ALLOWED");
        }

        // El estado "exhausted" aplica para cupos de usuarios registrados;
        // los invitados pueden entrar siempre que el código no haya sido revocado.
        if (shareCode.Status == "revoked")
        {
            throw new AppException("Share code has been revoked.", 400);
        }

        if (shareCode.ExpiresAt.HasValue && shareCode.ExpiresAt.Value < DateTime.UtcNow)
        {
            throw new AppException("Share code has expired.", 400);
        }

        if (shareCode.QuizId is null || shareCode.Quiz is null)
        {
            throw new AppException("Share code is not linked to a valid quiz.", 400);
        }

        if (shareCode.Quiz.PublicationStatus != "published")
        {
            throw new AppException("This quiz is not available for practice.", 403);
        }

        var now = DateTime.UtcNow;
        var token = GenerateToken();

        var visit = new GuestVisit
        {
            GuestVisitId = Guid.NewGuid(),
            QuizId = shareCode.QuizId.Value,
            Token = token,
            CreatedAt = now,
            ExpiresAt = now.Add(VisitTtl),
            LastActivityAt = now,
        };

        dbContext.GuestVisits.Add(visit);
        await dbContext.SaveChangesAsync(cancellationToken);

        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == visit.QuizId, cancellationToken);

        return MapVisit(visit, shareCode.Quiz, questionCount);
    }

    public async Task<GuestVisitDto?> GetVisitAsync(
        string token,
        CancellationToken cancellationToken = default)
    {
        var visit = await dbContext.GuestVisits
            .AsNoTracking()
            .Include(v => v.Quiz)
            .FirstOrDefaultAsync(v => v.Token == token, cancellationToken);

        if (visit is null || visit.ExpiresAt < DateTime.UtcNow)
        {
            return null;
        }

        var questionCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == visit.QuizId, cancellationToken);

        return MapVisit(visit, visit.Quiz, questionCount);
    }

    public async Task<PracticeSessionDto> StartPracticeAsync(
        Guid guestVisitId,
        string token,
        GuestStartPracticeRequest request,
        CancellationToken cancellationToken = default)
    {
        var visit = await ResolveVisitAsync(guestVisitId, token, cancellationToken);

        var activeCount = await dbContext.PracticeSessions
            .CountAsync(
                s => s.GuestVisitId == guestVisitId && s.Status == "in_progress",
                cancellationToken);

        if (activeCount > 0)
        {
            throw new AppException(
                "You already have an active practice session.",
                400,
                errorCode: "ACTIVE_PRACTICE_SESSION");
        }

        var totalCount = await dbContext.PracticeSessions
            .CountAsync(s => s.GuestVisitId == guestVisitId, cancellationToken);

        if (totalCount >= MaxAttemptsPerVisit)
        {
            throw new AppException("Maximum attempts reached for this visit.", 400);
        }

        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == visit.QuizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.PublicationStatus != "published")
        {
            throw new AppException("Quiz is not published.", 403);
        }

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Include(q => q.QuestionType)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .Where(q => q.QuizId == visit.QuizId)
            .OrderBy(q => q.SortOrder)
            .ToListAsync(cancellationToken);

        if (questions.Count == 0)
        {
            throw new AppException("Quiz has no questions.", 400);
        }

        var questionIds = questions.Select(q => q.QuestionId).ToList();
        var justificationsByQuestionId = await dbContext.QuestionJustifications
            .AsNoTracking()
            .Include(j => j.Sources)
            .Where(j => questionIds.Contains(j.QuestionId))
            .ToDictionaryAsync(j => j.QuestionId, cancellationToken);

        var randomize = request.RandomizeQuestions ?? quiz.RandomizeQuestions;
        var questionList = PracticeSessionOrdering.OrderQuestions(questions, randomize);

        var sessionId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        var session = new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = null,
            GuestVisitId = guestVisitId,
            QuizId = visit.QuizId,
            StartedAt = now,
            ScorePossible = questionList.Sum(q => q.Points),
            Status = "in_progress",
            RandomizationStrategy = "server_random",
            ShowElapsedTimer = request.ShowElapsedTimer,
            LastActivityAt = now,
            CreatedAt = now,
        };

        const string questionImageKey = "QUESTION_IMAGE";

        var autoDetectChanges = dbContext.ChangeTracker.AutoDetectChangesEnabled;
        dbContext.ChangeTracker.AutoDetectChangesEnabled = false;
        try
        {
            var displayOrder = 0;
            foreach (var question in questionList)
            {
                displayOrder++;
                var snapshotId = Guid.NewGuid();
                var seed = Guid.NewGuid().ToString("N");

                var allOptions = question.AnswerOptions.Where(o => o.IsActive).ToList();
                var stemOption = allOptions.FirstOrDefault(o =>
                    string.Equals(o.StableKey, questionImageKey, StringComparison.OrdinalIgnoreCase));
                var selectableOptions = allOptions
                    .Where(o => !string.Equals(o.StableKey, questionImageKey, StringComparison.OrdinalIgnoreCase))
                    .ToList();

                var correctIds = question.CorrectAnswerOptions
                    .Select(c => c.AnswerOptionId)
                    .ToHashSet();

                var orderedOptions = question.RandomizeAnswerOptions
                    ? PracticeSessionOrdering.ShuffleAnswerOptions(selectableOptions, seed)
                    : selectableOptions.OrderBy(o => o.DefaultSortOrder).ToList();

                var labels = AnswerGradingService.BuildDisplayLabels(orderedOptions.Count);
                var answerSnapshots = new List<PracticeAnswerOptionSnapshot>();

                if (stemOption is not null)
                {
                    answerSnapshots.Add(new PracticeAnswerOptionSnapshot
                    {
                        PracticeAnswerOptionSnapshotId = Guid.NewGuid(),
                        PracticeQuestionSnapshotId = snapshotId,
                        AnswerOptionId = stemOption.AnswerOptionId,
                        StableKeySnapshot = stemOption.StableKey,
                        DisplayOrder = 0,
                        DisplayLabel = string.Empty,
                        AnswerTextSnapshot = stemOption.AnswerText,
                        MediaAssetIdSnapshot = stemOption.MediaAssetId,
                        IsCorrectSnapshot = false,
                        WasSelected = false,
                        CreatedAt = now,
                    });
                }

                for (var i = 0; i < orderedOptions.Count; i++)
                {
                    var option = orderedOptions[i];
                    answerSnapshots.Add(new PracticeAnswerOptionSnapshot
                    {
                        PracticeAnswerOptionSnapshotId = Guid.NewGuid(),
                        PracticeQuestionSnapshotId = snapshotId,
                        AnswerOptionId = option.AnswerOptionId,
                        StableKeySnapshot = option.StableKey,
                        DisplayOrder = i + 1,
                        DisplayLabel = labels[i],
                        AnswerTextSnapshot = option.AnswerText,
                        MediaAssetIdSnapshot = option.MediaAssetId,
                        IsCorrectSnapshot = correctIds.Contains(option.AnswerOptionId),
                        WasSelected = false,
                        CreatedAt = now,
                    });
                }

                justificationsByQuestionId.TryGetValue(question.QuestionId, out var justification);
                var (justificationText, justificationSourcesJson) =
                    QuestionJustificationMapper.BuildPracticeSnapshot(justification);

                session.QuestionSnapshots.Add(new PracticeQuestionSnapshot
                {
                    PracticeQuestionSnapshotId = snapshotId,
                    PracticeSessionId = sessionId,
                    QuestionId = question.QuestionId,
                    QuestionTypeCodeSnapshot = question.QuestionType.Code,
                    QuestionTextSnapshot = question.QuestionText,
                    PointsPossible = question.Points,
                    DisplayOrder = displayOrder,
                    AnswerStatus = "unanswered",
                    RandomizationSeed = seed,
                    JustificationTextSnapshot = justificationText,
                    JustificationSourcesSnapshot = justificationSourcesJson,
                    CreatedAt = now,
                    AnswerOptionSnapshots = answerSnapshots,
                });
            }

            visit.LastActivityAt = now;
            await PracticeSnapshotBulkInserter.InsertAsync(
                dbContext,
                session,
                new PracticeSnapshotBulkInserter.PersistOptions
                {
                    GuestVisitId = guestVisitId,
                    GuestVisitLastActivityAt = now,
                },
                cancellationToken);
        }
        finally
        {
            dbContext.ChangeTracker.AutoDetectChangesEnabled = autoDetectChanges;
        }

        return MapSession(session);
    }

    public async Task<PracticeActiveSessionSummaryDto?> GetActiveSessionAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);

        return await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(s => s.GuestVisitId == guestVisitId && s.Status == "in_progress")
            .OrderByDescending(s => s.LastActivityAt ?? s.StartedAt)
            .Select(s => new PracticeActiveSessionSummaryDto
            {
                PracticeSessionId = s.PracticeSessionId,
                QuizId = s.QuizId,
                StartedAt = s.StartedAt,
                PausedAt = s.PausedAt,
                LastActivityAt = s.LastActivityAt ?? s.StartedAt,
                CurrentQuestionIndex = s.CurrentQuestionIndex ?? 0,
                TotalQuestions = s.QuestionSnapshots.Count,
                AnsweredCount = s.QuestionSnapshots.Count(q => q.AnswerStatus == "answered"),
            })
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task AbandonSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);
        var session = await LoadGuestSessionInProgressAsync(
            guestVisitId,
            sessionId,
            cancellationToken);

        var now = DateTime.UtcNow;
        session.Status = "abandoned";
        session.FinishedAt = now;
        session.LastActivityAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<PracticeSessionDto> GetSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);
        var session = await LoadGuestSessionAsync(guestVisitId, sessionId, cancellationToken);
        return MapSession(session);
    }

    public async Task<SubmitAnswerResultDto> SubmitAnswerAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        SubmitAnswerRequest request,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);

        var questionSnapshot = await dbContext.PracticeQuestionSnapshots
            .Include(q => q.AnswerOptionSnapshots)
            .Include(q => q.PracticeSession)
            .FirstOrDefaultAsync(
                q => q.PracticeQuestionSnapshotId == practiceQuestionSnapshotId
                    && q.PracticeSessionId == sessionId
                    && q.PracticeSession.GuestVisitId == guestVisitId
                    && q.PracticeSession.Status == "in_progress",
                cancellationToken)
            ?? throw new AppException("Question snapshot not found.", 404);

        var session = questionSnapshot.PracticeSession;

        var supportsMultiple = await dbContext.QuestionTypes
            .AsNoTracking()
            .Where(t => t.Code == questionSnapshot.QuestionTypeCodeSnapshot)
            .Select(t => t.SupportsMultipleCorrectAnswers)
            .FirstOrDefaultAsync(cancellationToken);
        var scoringPolicy = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuestionId == questionSnapshot.QuestionId)
            .Select(q => q.ScoringPolicy)
            .FirstOrDefaultAsync(cancellationToken) ?? "strict";

        var questionType = supportsMultiple;

        var selectedIds = PracticeAnswerSelectionWriter.NormalizeSelectedIds(
            request.SelectedAnswerOptionIds,
            supportsMultiple);
        if (selectedIds.Count == 0)
        {
            throw new AppException("At least one answer option id is required.", 400);
        }

        var validOptionIds = questionSnapshot.AnswerOptionSnapshots
            .Select(a => a.AnswerOptionId)
            .ToHashSet();

        foreach (var selectedId in selectedIds)
        {
            if (!validOptionIds.Contains(selectedId))
            {
                throw new AppException("Invalid answer option id.", 400);
            }
        }

        var correctIds = questionSnapshot.AnswerOptionSnapshots
            .Where(a => a.IsCorrectSnapshot)
            .Select(a => a.AnswerOptionId)
            .ToHashSet();

        if (supportsMultiple)
        {
            scoringPolicy = AnswerGradingService.PartialScoringPolicy;
        }

        var grading = AnswerGradingService.GradeAnswer(
            selectedIds.ToHashSet(),
            correctIds,
            supportsMultiple,
            scoringPolicy,
            questionSnapshot.PointsPossible);

        var now = DateTime.UtcNow;
        PracticeAnswerSelectionWriter.ApplySelection(
            questionSnapshot,
            selectedIds,
            supportsMultiple,
            now);

        questionSnapshot.AnswerStatus = "answered";
        questionSnapshot.IsCorrect = grading.IsFullyCorrect;
        questionSnapshot.PointsAwarded = grading.PointsAwarded;
        questionSnapshot.SubmittedAt = now;
        session.LastActivityAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);

        return new SubmitAnswerResultDto
        {
            PracticeQuestionSnapshotId = practiceQuestionSnapshotId,
            Accepted = true,
            AnswerStatus = questionSnapshot.AnswerStatus,
        };
    }

    public async Task UpdateProgressAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);
        var session = await LoadGuestSessionInProgressAsync(guestVisitId, sessionId, cancellationToken);

        var questionCount = session.QuestionSnapshots.Count;
        if (request.CurrentQuestionIndex < 0 || request.CurrentQuestionIndex >= questionCount)
        {
            throw new AppException("Invalid question index.", 400);
        }

        var now = DateTime.UtcNow;
        session.CurrentQuestionIndex = request.CurrentQuestionIndex;
        session.ElapsedSecondsBeforePause = Math.Max(0, request.ElapsedSecondsBeforePause);
        session.PausedAt = now;
        session.LastActivityAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<PracticeSessionResultDto> FinishSessionAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);
        var session = await LoadGuestSessionInProgressAsync(guestVisitId, sessionId, cancellationToken);

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

        var now = DateTime.UtcNow;
        session.Status = "finished";
        session.FinishedAt = now;
        session.DurationSeconds = (int)(now - session.StartedAt).TotalSeconds;
        session.ScoreObtained = scoreObtained;
        session.CorrectAnswers = correct;
        session.IncorrectAnswers = incorrect;
        session.OmittedAnswers = omitted;
        session.LastActivityAt = now;

        var visit = await dbContext.GuestVisits.FindAsync([guestVisitId], cancellationToken);
        if (visit is not null)
        {
            visit.LastActivityAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var percentage = session.ScorePossible > 0
            ? Math.Round(scoreObtained / session.ScorePossible * 100, 2)
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

        return new PracticeSessionResultDto
        {
            PracticeSessionId = session.PracticeSessionId,
            ScoreObtained = scoreObtained,
            ScorePossible = session.ScorePossible,
            Percentage = percentage,
            CorrectAnswers = correct,
            IncorrectAnswers = incorrect,
            OmittedAnswers = omitted,
            CanViewDetailedReview = true,
            QuestionsToReview = questionsToReview,
        };
    }

    public async Task<IReadOnlyList<GuestAttemptSummaryDto>> ListAttemptsAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(s => s.GuestVisitId == guestVisitId && s.Status != "in_progress")
            .OrderByDescending(s => s.FinishedAt ?? s.StartedAt)
            .ToListAsync(cancellationToken);

        return sessions
            .Select(s => new GuestAttemptSummaryDto
            {
                PracticeSessionId = s.PracticeSessionId,
                ScoreObtained = s.ScoreObtained,
                ScorePossible = s.ScorePossible,
                Status = s.Status,
                StartedAt = s.StartedAt,
                FinishedAt = s.FinishedAt,
                DurationSeconds = s.DurationSeconds,
                ShowElapsedTimer = s.ShowElapsedTimer,
            })
            .ToList();
    }

    public async Task<TeacherPracticeReviewDto> GetAttemptReviewAsync(
        Guid guestVisitId,
        string token,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        await ResolveVisitAsync(guestVisitId, token, cancellationToken);

        var session = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstOrDefaultAsync(
                s => s.PracticeSessionId == sessionId && s.GuestVisitId == guestVisitId,
                cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        return TeacherReviewMapper.MapReview(session, mediaService);
    }

    public async Task LeaveAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken = default)
    {
        var visit = await dbContext.GuestVisits
            .FirstOrDefaultAsync(v => v.GuestVisitId == guestVisitId && v.Token == token, cancellationToken);

        if (visit is null)
        {
            return;
        }

        await PracticeSessionCleanup.DeleteSessionsForGuestVisitAsync(
            dbContext,
            guestVisitId,
            cancellationToken);

        dbContext.GuestVisits.Remove(visit);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task PurgeExpiredVisitsAsync(CancellationToken cancellationToken = default)
    {
        var expired = await dbContext.GuestVisits
            .Where(v => v.ExpiresAt < DateTime.UtcNow)
            .ToListAsync(cancellationToken);

        if (expired.Count == 0)
        {
            return;
        }

        foreach (var visit in expired)
        {
            await PracticeSessionCleanup.DeleteSessionsForGuestVisitAsync(
                dbContext,
                visit.GuestVisitId,
                cancellationToken);
        }

        dbContext.GuestVisits.RemoveRange(expired);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<GuestVisit> ResolveVisitAsync(
        Guid guestVisitId,
        string token,
        CancellationToken cancellationToken)
    {
        var visit = await dbContext.GuestVisits
            .FirstOrDefaultAsync(
                v => v.GuestVisitId == guestVisitId && v.Token == token,
                cancellationToken)
            ?? throw new AppException("Guest visit not found.", 404);

        if (visit.ExpiresAt < DateTime.UtcNow)
        {
            throw new AppException("Guest visit has expired.", 410);
        }

        return visit;
    }

    private async Task<PracticeSession> LoadGuestSessionAsync(
        Guid guestVisitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var session = await dbContext.PracticeSessions
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstOrDefaultAsync(
                s => s.PracticeSessionId == sessionId && s.GuestVisitId == guestVisitId,
                cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        return session;
    }

    private async Task<PracticeSession> LoadGuestSessionInProgressAsync(
        Guid guestVisitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var session = await LoadGuestSessionAsync(guestVisitId, sessionId, cancellationToken);

        if (session.Status != "in_progress")
        {
            throw new AppException("Practice session is not in progress.", 400);
        }

        return session;
    }

    private PracticeSessionDto MapSession(PracticeSession session)
    {
        const string questionImageKey = "QUESTION_IMAGE";

        var questions = session.QuestionSnapshots
            .OrderBy(q => q.DisplayOrder)
            .Select(q =>
            {
                var snapshots = q.AnswerOptionSnapshots.OrderBy(a => a.DisplayOrder).ToList();
                var stemSnapshot = snapshots.FirstOrDefault(a =>
                    string.Equals(a.StableKeySnapshot, questionImageKey, StringComparison.OrdinalIgnoreCase));
                var answerSnapshots = snapshots
                    .Where(a => !string.Equals(
                        a.StableKeySnapshot,
                        questionImageKey,
                        StringComparison.OrdinalIgnoreCase))
                    .ToList();

                return new PracticeQuestionDto
                {
                    PracticeQuestionSnapshotId = q.PracticeQuestionSnapshotId,
                    QuestionId = q.QuestionId,
                    DisplayOrder = q.DisplayOrder,
                    QuestionText = q.QuestionTextSnapshot,
                    QuestionType = q.QuestionTypeCodeSnapshot,
                    QuestionMediaUrl = stemSnapshot?.MediaAssetIdSnapshot is Guid mediaId
                        ? mediaService.BuildPublicUrl(mediaId)
                        : null,
                    AnswerStatus = q.AnswerStatus,
                    SelectedAnswerOptionIds = answerSnapshots
                        .Where(a => a.WasSelected)
                        .Select(a => a.AnswerOptionId)
                        .ToList(),
                    Answers = answerSnapshots
                        .Select(a => new PracticeAnswerOptionDto
                        {
                            AnswerOptionId = a.AnswerOptionId,
                            DisplayOrder = a.DisplayOrder,
                            DisplayLabel = a.DisplayLabel,
                            Text = a.AnswerTextSnapshot,
                            MediaAssetId = a.MediaAssetIdSnapshot,
                            MediaUrl = a.MediaAssetIdSnapshot.HasValue
                                ? mediaService.BuildPublicUrl(a.MediaAssetIdSnapshot.Value)
                                : null,
                        })
                        .ToList(),
                };
            })
            .ToList();

        var total = questions.Count;
        var answered = questions.Count(q => q.AnswerStatus == "answered");

        return new PracticeSessionDto
        {
            PracticeSessionId = session.PracticeSessionId,
            QuizId = session.QuizId,
            Status = session.Status,
            StartedAt = session.StartedAt,
            ShowElapsedTimer = session.ShowElapsedTimer,
            CurrentQuestionIndex = session.CurrentQuestionIndex ?? 0,
            ElapsedSecondsBeforePause = session.ElapsedSecondsBeforePause,
            AnsweredCount = answered,
            TotalQuestions = total,
            Questions = questions,
        };
    }

    private static GuestVisitDto MapVisit(GuestVisit visit, Quiz quiz, int questionCount) => new()
    {
        GuestVisitId = visit.GuestVisitId,
        Token = visit.Token,
        QuizId = visit.QuizId,
        QuizTitle = quiz.Title,
        QuizDescription = quiz.Description,
        QuestionCount = questionCount,
        ExpiresAt = visit.ExpiresAt,
    };

    private static string GenerateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }
}
