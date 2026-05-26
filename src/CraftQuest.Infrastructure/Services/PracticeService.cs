using CraftQuest.Application.Services;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;
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

        if (request.AssignmentId.HasValue)
        {
            await ValidateAssignmentPracticeWindowAsync(
                studentUserId,
                request.AssignmentId.Value,
                request.QuizId,
                request.ClientUtcOffsetMinutes,
                cancellationToken);
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
            .Where(q => q.QuizId == request.QuizId && q.DeletedAt == null)
            .OrderBy(q => q.SortOrder)
            .ToListAsync(cancellationToken);

        if (questions.Count == 0)
        {
            throw new AppException("Quiz has no questions.", 400);
        }

        var randomizeQuestions = request.RandomizeQuestions ?? quiz.RandomizeQuestions;
        var questionList = randomizeQuestions
            ? questions.OrderBy(_ => Random.Shared.Next()).ToList()
            : questions;

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
                ? Shuffle(selectableOptions, seed)
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
        var session = await LoadSessionForStudentAsync(studentUserId, sessionId, cancellationToken);

        var questionSnapshot = session.QuestionSnapshots
            .FirstOrDefault(q => q.PracticeQuestionSnapshotId == practiceQuestionSnapshotId)
            ?? throw new AppException("Question snapshot not found.", 404);

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

        var isCorrect = AnswerGradingService.IsAnswerCorrect(
            selectedIds.ToHashSet(),
            correctIds,
            questionType.SupportsMultipleCorrectAnswers);

        var now = DateTime.UtcNow;
        foreach (var answer in questionSnapshot.AnswerOptionSnapshots)
        {
            answer.WasSelected = selectedIds.Contains(answer.AnswerOptionId);
            answer.SelectedAt = answer.WasSelected ? now : null;
        }

        questionSnapshot.AnswerStatus = "answered";
        questionSnapshot.IsCorrect = isCorrect;
        questionSnapshot.PointsAwarded = isCorrect ? questionSnapshot.PointsPossible : 0;
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

        var correct = 0;
        var incorrect = 0;
        var omitted = 0;
        decimal scoreObtained = 0;

        foreach (var question in session.QuestionSnapshots)
        {
            switch (question.AnswerStatus)
            {
                case "answered" when question.IsCorrect == true:
                    correct++;
                    scoreObtained += question.PointsAwarded;
                    break;
                case "answered":
                    incorrect++;
                    break;
                case "skipped":
                default:
                    omitted++;
                    question.AnswerStatus = "omitted";
                    break;
            }
        }

        session.Status = "finished";
        session.FinishedAt = DateTime.UtcNow;
        session.DurationSeconds = (int)(session.FinishedAt.Value - session.StartedAt).TotalSeconds;
        session.ScoreObtained = scoreObtained;
        session.CorrectAnswers = correct;
        session.IncorrectAnswers = incorrect;
        session.OmittedAnswers = omitted;

        await analyticsService.RecordFinishedPracticeSessionAsync(session, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        var percentage = session.ScorePossible > 0
            ? Math.Round(scoreObtained / session.ScorePossible * 100, 2)
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
            ScoreObtained = scoreObtained,
            ScorePossible = session.ScorePossible,
            Percentage = percentage,
            CorrectAnswers = correct,
            IncorrectAnswers = incorrect,
            OmittedAnswers = omitted,
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

    private static List<QuestionAnswerOption> Shuffle(List<QuestionAnswerOption> options, string seed)
    {
        var list = options.ToList();
        var random = new Random(HashCode.Combine(seed.GetHashCode()));
        for (var i = list.Count - 1; i > 0; i--)
        {
            var j = random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }

        return list;
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

        var questionStats = new Dictionary<Guid, (int Attempts, int Correct, int Incorrect, int Omitted)>();
        var optionSelected = new Dictionary<Guid, int>();

        foreach (var session in sessions)
        {
            foreach (var snapshot in session.QuestionSnapshots)
            {
                if (!questionStats.TryGetValue(snapshot.QuestionId, out var stats))
                {
                    stats = (0, 0, 0, 0);
                }

                stats.Attempts++;
                switch (snapshot.AnswerStatus)
                {
                    case "answered" when snapshot.IsCorrect == true:
                        stats.Correct++;
                        break;
                    case "answered":
                        stats.Incorrect++;
                        break;
                    default:
                        stats.Omitted++;
                        break;
                }

                questionStats[snapshot.QuestionId] = stats;

                foreach (var answer in snapshot.AnswerOptionSnapshots.Where(a => a.WasSelected))
                {
                    optionSelected[answer.AnswerOptionId] =
                        optionSelected.GetValueOrDefault(answer.AnswerOptionId) + 1;
                }
            }
        }

        var questionAnalytics = questions
            .Select(q =>
            {
                questionStats.TryGetValue(q.QuestionId, out var stats);
                var attempts = stats.Attempts;
                var correctIds = q.CorrectAnswerOptions
                    .Select(c => c.AnswerOptionId)
                    .ToHashSet();

                return new QuestionAnalyticsDto
                {
                    QuestionId = q.QuestionId,
                    QuestionText = q.QuestionText,
                    AttemptsCount = attempts,
                    CorrectCount = stats.Correct,
                    IncorrectCount = stats.Incorrect,
                    OmittedCount = stats.Omitted,
                    AnswerOptions = q.AnswerOptions
                        .OrderBy(o => o.DefaultSortOrder)
                        .Select(o =>
                        {
                            var selected = optionSelected.GetValueOrDefault(o.AnswerOptionId);
                            return new AnswerOptionAnalyticsDto
                            {
                                AnswerOptionId = o.AnswerOptionId,
                                StableKey = o.StableKey,
                                Text = o.AnswerText,
                                IsCorrect = correctIds.Contains(o.AnswerOptionId),
                                SelectedCount = selected,
                                SelectionRate = attempts > 0
                                    ? Math.Round((decimal)selected / attempts * 100, 2)
                                    : 0,
                            };
                        })
                        .ToList(),
                };
            })
            .ToList();

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
            var finishedAttempts = await dbContext.PracticeSessions.CountAsync(
                ps => ps.AssignmentId == assignmentId
                    && ps.StudentUserId == studentUserId
                    && ps.Status == "finished",
                cancellationToken);

            if (finishedAttempts >= assignment.MaxAttempts.Value)
            {
                throw new AppException(
                    "You have reached the maximum number of attempts for this assignment.",
                    403,
                    errorCode: "ASSIGNMENT_MAX_ATTEMPTS");
            }
        }
    }
}
