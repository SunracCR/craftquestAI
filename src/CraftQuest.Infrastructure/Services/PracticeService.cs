using CraftQuest.Application.Analytics;
using CraftQuest.Application.Services;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Application.Services.Teacher;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PracticeService(
    CraftQuestDbContext dbContext,
    IShareCodeService shareCodeService,
    IAnalyticsService analyticsService,
    IMediaService mediaService) : IPracticeService
{
    private const int InProgressExpiryDays = 30;

    public async Task<PracticeSessionDto> StartSessionAsync(
        Guid studentUserId,
        StartPracticeSessionRequest request,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == request.QuizId && q.DeletedAt == null, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.PublicationStatus != "published")
        {
            throw new AppException("Quiz is not published.", 403);
        }

        Assignment? assignment = null;
        if (request.AssignmentId.HasValue)
        {
            await ValidateAssignmentPracticeWindowAsync(
                studentUserId,
                request.AssignmentId.Value,
                request.QuizId,
                request.ClientUtcOffsetMinutes,
                cancellationToken);

            assignment = await dbContext.Assignments
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    a => a.AssignmentId == request.AssignmentId.Value,
                    cancellationToken)
                ?? throw new AppException("Assignment not found.", 404);
        }
        else
        {
            var hasSharedAccess = await shareCodeService.HasQuizAccessAsync(
                studentUserId,
                request.QuizId,
                cancellationToken);
            if (!hasSharedAccess)
            {
                throw new AppException(
                    "You do not have access to practice this quiz. Redeem a share code first.",
                    403);
            }
        }

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Include(q => q.QuestionType)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .Include(q => q.Justification!)
                .ThenInclude(j => j.Sources)
            .Where(q => q.QuizId == request.QuizId && q.DeletedAt == null)
            .OrderBy(q => q.SortOrder)
            .ToListAsync(cancellationToken);

        if (questions.Count == 0)
        {
            throw new AppException("Quiz has no questions.", 400);
        }

        var randomizeQuestions = PracticeSessionOrdering.ResolveRandomizeQuestions(
            request.AssignmentId.HasValue,
            request.RandomizeQuestions,
            quiz.RandomizeQuestions,
            assignment?.RandomizeQuestions ?? false,
            assignment?.AllowStudentRandomizeQuestions ?? false);
        var questionList = PracticeSessionOrdering.OrderQuestions(questions, randomizeQuestions);

        var sessionId = Guid.NewGuid();
        var session = new PracticeSession
        {
            PracticeSessionId = sessionId,
            StudentUserId = studentUserId,
            QuizId = request.QuizId,
            ClassId = request.ClassId,
            AssignmentId = request.AssignmentId,
            StartedAt = DateTime.UtcNow,
            ScorePossible = questionList.Sum(q => q.Points),
            Status = "in_progress",
            RandomizationStrategy = "server_random",
            ShowElapsedTimer = request.ShowElapsedTimer,
            LastActivityAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
        };

        const string questionImageKey = "QUESTION_IMAGE";

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
                    CreatedAt = DateTime.UtcNow,
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
                    CreatedAt = DateTime.UtcNow,
                });
            }

            var (justificationText, justificationSourcesJson) =
                QuestionJustificationMapper.BuildPracticeSnapshot(question.Justification);

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
                CreatedAt = DateTime.UtcNow,
                AnswerOptionSnapshots = answerSnapshots,
            });
        }

        dbContext.PracticeSessions.Add(session);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapSession(session);
    }

    public async Task<SubmitAnswerResultDto> SubmitAnswerAsync(
        Guid studentUserId,
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        SubmitAnswerRequest request,
        CancellationToken cancellationToken = default)
    {
        var questionSnapshot = await dbContext.PracticeQuestionSnapshots
            .Include(q => q.AnswerOptionSnapshots)
            .Include(q => q.PracticeSession)
            .FirstOrDefaultAsync(
                q => q.PracticeQuestionSnapshotId == practiceQuestionSnapshotId
                    && q.PracticeSessionId == sessionId
                    && q.PracticeSession.StudentUserId == studentUserId
                    && q.PracticeSession.Status == "in_progress",
                cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        var session = questionSnapshot.PracticeSession;

        var selectedIds = request.SelectedAnswerOptionIds?.Distinct().ToList() ?? [];
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
                throw new AppException(
                    "Invalid answer option id. Submit AnswerOptionId values only, not display labels.",
                    400);
            }
        }

        var questionType = await dbContext.QuestionTypes
            .AsNoTracking()
            .FirstAsync(t => t.Code == questionSnapshot.QuestionTypeCodeSnapshot, cancellationToken);

        var correctIds = questionSnapshot.AnswerOptionSnapshots
            .Where(a => a.IsCorrectSnapshot)
            .Select(a => a.AnswerOptionId)
            .ToHashSet();

        var scoringPolicy = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuestionId == questionSnapshot.QuestionId)
            .Select(q => q.ScoringPolicy)
            .FirstOrDefaultAsync(cancellationToken) ?? "strict";

        if (questionType.SupportsMultipleCorrectAnswers)
        {
            scoringPolicy = AnswerGradingService.PartialScoringPolicy;
        }

        var grading = AnswerGradingService.GradeAnswer(
            selectedIds.ToHashSet(),
            correctIds,
            questionType.SupportsMultipleCorrectAnswers,
            scoringPolicy,
            questionSnapshot.PointsPossible);

        var now = DateTime.UtcNow;
        foreach (var answer in questionSnapshot.AnswerOptionSnapshots)
        {
            answer.WasSelected = selectedIds.Contains(answer.AnswerOptionId);
            answer.SelectedAt = answer.WasSelected ? now : null;
        }

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

    public async Task<PracticeSessionResultDto> FinishSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);

        ApplyPartialSessionScoring(session);

        session.Status = "finished";
        session.FinishedAt = DateTime.UtcNow;
        session.DurationSeconds = (int)(session.FinishedAt.Value - session.StartedAt).TotalSeconds;

        await analyticsService.RecordFinishedPracticeSessionAsync(session, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        var percentage = session.ScorePossible > 0
            ? Math.Round(session.ScoreObtained / session.ScorePossible * 100, 2)
            : 0;

        var revealContext = await GetAssignmentRevealContextAsync(session, cancellationToken);

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

        var scoreTrend = await GetScoreTrendVsPreviousAsync(
            studentUserId,
            session,
            percentage,
            cancellationToken);

        return new PracticeSessionResultDto
        {
            PracticeSessionId = session.PracticeSessionId,
            ScoreObtained = session.ScoreObtained,
            ScorePossible = session.ScorePossible,
            Percentage = percentage,
            CorrectAnswers = session.CorrectAnswers,
            IncorrectAnswers = session.IncorrectAnswers,
            OmittedAnswers = session.OmittedAnswers,
            CanViewDetailedReview = revealContext.CanViewDetailedReview,
            AssignmentShowCorrectAnswersMode = revealContext.ShowCorrectAnswersMode,
            AssignmentDueAt = revealContext.AssignmentDueAt,
            ScoreTrendVsPrevious = scoreTrend,
            QuestionsToReview = questionsToReview,
        };
    }

    private async Task<decimal?> GetScoreTrendVsPreviousAsync(
        Guid studentUserId,
        PracticeSession session,
        decimal currentPercentage,
        CancellationToken cancellationToken)
    {
        var previousQuery = dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.StudentUserId == studentUserId
                && ps.QuizId == session.QuizId
                && ps.Status == "finished"
                && ps.PracticeSessionId != session.PracticeSessionId
                && ps.FinishedAt < session.FinishedAt);

        if (session.AssignmentId.HasValue)
        {
            previousQuery = previousQuery.Where(ps => ps.AssignmentId == session.AssignmentId);
        }
        else
        {
            previousQuery = previousQuery.Where(ps => ps.AssignmentId == null);
        }

        var previous = await previousQuery
            .OrderByDescending(ps => ps.FinishedAt)
            .Select(ps => new { ps.ScoreObtained, ps.ScorePossible })
            .FirstOrDefaultAsync(cancellationToken);

        if (previous is null || previous.ScorePossible <= 0)
        {
            return null;
        }

        var previousPct = Math.Round(previous.ScoreObtained / previous.ScorePossible * 100, 2);
        return Math.Round(currentPercentage - previousPct, 2);
    }

    private sealed record AssignmentRevealContext(
        bool CanViewDetailedReview,
        string? ShowCorrectAnswersMode,
        DateTime? AssignmentDueAt);

    private async Task<AssignmentRevealContext> GetAssignmentRevealContextAsync(
        PracticeSession session,
        CancellationToken cancellationToken)
    {
        if (!session.AssignmentId.HasValue)
        {
            return new AssignmentRevealContext(true, null, null);
        }

        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .FirstOrDefaultAsync(
                a => a.AssignmentId == session.AssignmentId,
                cancellationToken);

        if (assignment is null)
        {
            return new AssignmentRevealContext(true, null, null);
        }

        return new AssignmentRevealContext(
            AssignmentAnswerRevealHelper.CanStudentViewCorrectAnswers(assignment),
            assignment.ShowCorrectAnswersMode,
            assignment.DueAt);
    }

    private async Task<bool> CanStudentViewDetailedReviewAsync(
        PracticeSession session,
        CancellationToken cancellationToken)
    {
        var context = await GetAssignmentRevealContextAsync(session, cancellationToken);
        return context.CanViewDetailedReview;
    }

    public async Task<PracticeActiveSessionSummaryDto?> GetActiveSessionForQuizAsync(
        Guid studentUserId,
        Guid quizId,
        Guid? assignmentId = null,
        CancellationToken cancellationToken = default)
    {
        await ExpireStaleInProgressSessionsAsync(studentUserId, cancellationToken);

        var query = dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.QuestionSnapshots)
            .Where(s =>
                s.StudentUserId == studentUserId
                && s.QuizId == quizId
                && s.Status == "in_progress");

        query = assignmentId.HasValue
            ? query.Where(s => s.AssignmentId == assignmentId)
            : query.Where(s => s.AssignmentId == null);

        var session = await query
            .OrderByDescending(s => s.LastActivityAt ?? s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        return session is null ? null : MapSummary(session);
    }

    public async Task<IReadOnlyList<PracticeActiveSessionSummaryDto>> GetInProgressSessionsAsync(
        Guid studentUserId,
        CancellationToken cancellationToken = default)
    {
        await ExpireStaleInProgressSessionsAsync(studentUserId, cancellationToken);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.QuestionSnapshots)
            .Where(s => s.StudentUserId == studentUserId && s.Status == "in_progress")
            .OrderByDescending(s => s.LastActivityAt ?? s.StartedAt)
            .ToListAsync(cancellationToken);

        return sessions.Select(MapSummary).ToList();
    }

    public async Task<PracticeSessionDto> GetSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);
        return MapSession(session);
    }

    public async Task UpdateProgressAsync(
        Guid studentUserId,
        Guid sessionId,
        UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken = default)
    {
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);
        var questionCount = session.QuestionSnapshots.Count;

        if (request.CurrentQuestionIndex < 0
            || request.CurrentQuestionIndex >= questionCount)
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

    public async Task AbandonSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);
        var now = DateTime.UtcNow;
        session.Status = "abandoned";
        session.FinishedAt = now;
        session.LastActivityAt = now;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ForfeitSessionAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);

        if (session.Status != "in_progress")
        {
            throw new AppException("Practice session is not in progress.", 400);
        }

        if (!session.AssignmentId.HasValue)
        {
            throw new AppException(
                "Forfeit is only available for class assignment practice.",
                400);
        }

        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .FirstOrDefaultAsync(
                a => a.AssignmentId == session.AssignmentId.Value,
                cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (!assignment.ForfeitExitCountsAsAttempt
            || !assignment.MaxAttempts.HasValue
            || assignment.MaxAttempts < 1)
        {
            throw new AppException(
                "This assignment does not forfeit attempts on exit.",
                403,
                errorCode: "ASSIGNMENT_FORFEIT_NOT_ENABLED");
        }

        ApplyPartialSessionScoring(session);

        var now = DateTime.UtcNow;
        session.Status = "forfeited";
        session.FinishedAt = now;
        session.LastActivityAt = now;
        session.DurationSeconds = (int)(now - session.StartedAt).TotalSeconds;

        await dbContext.SaveChangesAsync(cancellationToken);
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
                case "skipped":
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

    private async Task ExpireStaleInProgressSessionsAsync(
        Guid studentUserId,
        CancellationToken cancellationToken)
    {
        var cutoff = DateTime.UtcNow.AddDays(-InProgressExpiryDays);
        var stale = await dbContext.PracticeSessions
            .Where(s =>
                s.StudentUserId == studentUserId
                && s.Status == "in_progress"
                && (s.LastActivityAt ?? s.StartedAt) < cutoff)
            .ToListAsync(cancellationToken);

        if (stale.Count == 0)
        {
            return;
        }

        var now = DateTime.UtcNow;
        foreach (var session in stale)
        {
            session.Status = "expired";
            session.FinishedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static PracticeActiveSessionSummaryDto MapSummary(PracticeSession session)
    {
        var total = session.QuestionSnapshots.Count;
        var answered = session.QuestionSnapshots.Count(q => q.AnswerStatus == "answered");
        var resumeIndex = ResolveResumeQuestionIndex(session);

        return new PracticeActiveSessionSummaryDto
        {
            PracticeSessionId = session.PracticeSessionId,
            QuizId = session.QuizId,
            StartedAt = session.StartedAt,
            PausedAt = session.PausedAt,
            LastActivityAt = session.LastActivityAt ?? session.StartedAt,
            CurrentQuestionIndex = resumeIndex,
            AnsweredCount = answered,
            TotalQuestions = total,
        };
    }

    private static int ResolveResumeQuestionIndex(PracticeSession session)
    {
        var questions = session.QuestionSnapshots.OrderBy(q => q.DisplayOrder).ToList();
        if (questions.Count == 0)
        {
            return 0;
        }

        if (session.CurrentQuestionIndex is >= 0 and var savedIndex
            && savedIndex < questions.Count)
        {
            return savedIndex;
        }

        var firstUnanswered = questions.FindIndex(q => q.AnswerStatus != "answered");
        return firstUnanswered >= 0 ? firstUnanswered : questions.Count - 1;
    }

    private async Task<PracticeSession> LoadSessionForStudentAsync(
        Guid studentUserId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var session = await dbContext.PracticeSessions
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstOrDefaultAsync(s => s.PracticeSessionId == sessionId, cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        if (session.StudentUserId != studentUserId)
        {
            throw new AppException("Practice session not found.", 404);
        }

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

        var answeredCount = session.QuestionSnapshots.Count(q => q.AnswerStatus == "answered");

        return new PracticeSessionDto
        {
            PracticeSessionId = session.PracticeSessionId,
            QuizId = session.QuizId,
            Status = session.Status,
            StartedAt = session.StartedAt,
            ShowElapsedTimer = session.ShowElapsedTimer,
            CurrentQuestionIndex = ResolveResumeQuestionIndex(session),
            ElapsedSecondsBeforePause = session.ElapsedSecondsBeforePause,
            AnsweredCount = answeredCount,
            TotalQuestions = questions.Count,
            Questions = questions,
        };
    }

    public async Task<IReadOnlyList<MyPracticeAttemptSummaryDto>> ListMyQuizAttemptsAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await EnsureSharedQuizPracticeAccessAsync(userId, quizId, cancellationToken);

        return await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(s => s.QuizId == quizId
                && s.StudentUserId == userId
                && s.AssignmentId == null
                && s.Status != "in_progress")
            .OrderByDescending(s => s.FinishedAt ?? s.StartedAt)
            .Select(s => new MyPracticeAttemptSummaryDto
            {
                PracticeSessionId = s.PracticeSessionId,
                ScoreObtained = s.ScoreObtained,
                ScorePossible = s.ScorePossible,
                Status = s.Status,
                FinishedAt = s.FinishedAt,
                StartedAt = s.StartedAt,
                DurationSeconds = s.DurationSeconds,
                ShowElapsedTimer = s.ShowElapsedTimer,
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<TeacherPracticeReviewDto> GetMySessionReviewAsync(
        Guid userId,
        Guid sessionId,
        CancellationToken cancellationToken = default)
    {
        var session = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(s => s.StudentUser)
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .FirstOrDefaultAsync(s => s.PracticeSessionId == sessionId, cancellationToken)
            ?? throw new AppException("Practice session not found.", 404);

        if (session.StudentUserId != userId)
        {
            throw new AppException("You do not have permission to view this session.", 403);
        }

        await EnsureCanViewOwnSessionAsync(userId, session, cancellationToken);

        var revealCorrectAnswers = await CanStudentViewDetailedReviewAsync(
            session,
            cancellationToken);

        return TeacherReviewMapper.MapReview(session, mediaService, revealCorrectAnswers);
    }

    public async Task<MyQuizPracticeAnalyticsDto> GetMyQuizPracticeAnalyticsAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await EnsureSharedQuizPracticeAccessAsync(userId, quizId, cancellationToken);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(s => s.QuizId == quizId
                && s.StudentUserId == userId
                && s.AssignmentId == null
                && s.Status == "finished")
            .Include(s => s.QuestionSnapshots)
            .ThenInclude(q => q.AnswerOptionSnapshots)
            .ToListAsync(cancellationToken);

        var percentages = sessions
            .Where(s => s.ScorePossible > 0)
            .Select(s => Math.Round(s.ScoreObtained / s.ScorePossible * 100, 2))
            .ToList();

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId && q.DeletedAt == null)
            .OrderBy(q => q.SortOrder)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .ToListAsync(cancellationToken);

        var questionAnalytics = DistractorAnalyticsAggregator.BuildFromSessions(questions, sessions);

        return new MyQuizPracticeAnalyticsDto
        {
            QuizId = quizId,
            FinishedAttempts = sessions.Count,
            AveragePercentage = percentages.Count > 0
                ? Math.Round(percentages.Average(), 2)
                : null,
            BestPercentage = percentages.Count > 0 ? percentages.Max() : null,
            Questions = questionAnalytics,
        };
    }

    private async Task EnsureSharedQuizPracticeAccessAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var hasAccess = await shareCodeService.HasQuizAccessAsync(
            userId,
            quizId,
            cancellationToken);
        if (!hasAccess)
        {
            throw new AppException(
                "You do not have access to this quiz. Redeem a share code first.",
                403);
        }
    }

    private async Task EnsureCanViewOwnSessionAsync(
        Guid userId,
        PracticeSession session,
        CancellationToken cancellationToken)
    {
        if (session.AssignmentId.HasValue)
        {
            var assignment = await dbContext.Assignments
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    a => a.AssignmentId == session.AssignmentId,
                    cancellationToken)
                ?? throw new AppException("Assignment not found.", 404);

            var isMember = await dbContext.ClassMembers.AnyAsync(
                m => m.ClassId == assignment.ClassId
                    && m.UserId == userId
                    && m.Status == "active",
                cancellationToken);

            if (!isMember)
            {
                throw new AppException("You do not have permission to view this session.", 403);
            }

            return;
        }

        await EnsureSharedQuizPracticeAccessAsync(userId, session.QuizId, cancellationToken);
    }

    private async Task ValidateAssignmentPracticeWindowAsync(
        Guid studentUserId,
        Guid assignmentId,
        Guid quizId,
        int? clientUtcOffsetMinutes,
        CancellationToken cancellationToken)
    {
        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.AssignmentId == assignmentId, cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (assignment.QuizId != quizId)
        {
            throw new AppException("Assignment does not match this quiz.", 400);
        }

        if (assignment.Status != "active")
        {
            throw new AppException(
                "This assignment is not open for practice.",
                403,
                errorCode: "ASSIGNMENT_NOT_OPEN");
        }

        var isMember = await dbContext.ClassMembers.AnyAsync(
            m => m.ClassId == assignment.ClassId
                && m.UserId == studentUserId
                && m.Status == "active",
            cancellationToken);

        if (!isMember)
        {
            throw new AppException("You are not a member of this class.", 403);
        }

        if (AssignmentDateHelper.IsNotYetOpen(assignment.StartsAt, clientUtcOffsetMinutes))
        {
            throw new AppException(
                "This assignment has not opened yet.",
                403,
                errorCode: "ASSIGNMENT_NOT_YET_OPEN");
        }

        if (AssignmentDateHelper.IsPastDue(assignment.DueAt, clientUtcOffsetMinutes))
        {
            throw new AppException(
                "This assignment is past its due date.",
                403,
                errorCode: "ASSIGNMENT_PAST_DUE");
        }

        if (assignment.MaxAttempts.HasValue)
        {
            var usedAttempts = await dbContext.PracticeSessions.CountAsync(
                ps => ps.AssignmentId == assignmentId
                    && ps.StudentUserId == studentUserId
                    && (ps.Status == "finished" || ps.Status == "forfeited"),
                cancellationToken);

            if (usedAttempts >= assignment.MaxAttempts.Value)
            {
                throw new AppException(
                    "You have reached the maximum number of attempts for this assignment.",
                    403,
                    errorCode: "ASSIGNMENT_MAX_ATTEMPTS");
            }
        }
    }
}
