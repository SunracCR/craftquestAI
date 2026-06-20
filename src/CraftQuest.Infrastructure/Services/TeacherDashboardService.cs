using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Quizzes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace CraftQuest.Infrastructure.Services;

public class TeacherDashboardService(CraftQuestDbContext dbContext, IMemoryCache memoryCache) : ITeacherDashboardService
{
    private static readonly TimeSpan DashboardCacheDuration = TimeSpan.FromSeconds(30);

    public async Task<TeacherDashboardDto> GetDashboardAsync(
        Guid teacherUserId,
        CancellationToken cancellationToken = default)
    {
        var cacheKey = $"teacher:dashboard:{teacherUserId:D}";
        if (memoryCache.TryGetValue(cacheKey, out TeacherDashboardDto? cached) && cached is not null)
        {
            return cached;
        }

        var classIds = await dbContext.TeacherClasses
            .AsNoTracking()
            .Where(c => c.TeacherUserId == teacherUserId && c.Status == "active")
            .Select(c => c.ClassId)
            .ToListAsync(cancellationToken);

        var activeClasses = classIds.Count;
        var assignmentIds = await GetTeacherAssignmentIdsAsync(teacherUserId, cancellationToken);
        var weekAgo = DateTime.UtcNow.AddDays(-7);

        var totalStudents = classIds.Count == 0
            ? 0
            : await dbContext.ClassMembers
                .AsNoTracking()
                .Where(m => classIds.Contains(m.ClassId) && m.Status == "active")
                .Select(m => m.UserId)
                .Distinct()
                .CountAsync(cancellationToken);

        var assignedQuizzes = classIds.Count == 0
            ? 0
            : await dbContext.Assignments
                .AsNoTracking()
                .Where(a => classIds.Contains(a.ClassId) && a.Status != "archived")
                .Select(a => a.QuizId)
                .Distinct()
                .CountAsync(cancellationToken);

        var sessionsThisWeek = assignmentIds.Count == 0
            ? 0
            : await dbContext.PracticeSessions
                .AsNoTracking()
                .CountAsync(
                    ps => ps.AssignmentId.HasValue
                        && assignmentIds.Contains(ps.AssignmentId.Value)
                        && ps.Status == "finished"
                        && ps.FinishedAt >= weekAgo
                        && ps.GuestVisitId == null,
                    cancellationToken);

        var uniqueActiveStudentsThisWeek = assignmentIds.Count == 0
            ? 0
            : await dbContext.PracticeSessions
                .AsNoTracking()
                .Where(ps => ps.AssignmentId.HasValue
                    && assignmentIds.Contains(ps.AssignmentId.Value)
                    && ps.Status == "finished"
                    && ps.FinishedAt >= weekAgo
                    && ps.GuestVisitId == null
                    && ps.StudentUserId != null)
                .Select(ps => ps.StudentUserId!.Value)
                .Distinct()
                .CountAsync(cancellationToken);

        var recentActivity = await GetActivityFeedAsync(teacherUserId, 20, cancellationToken, assignmentIds);
        var insights = await BuildInsightsAsync(teacherUserId, cancellationToken, assignmentIds);
        var urgentAssignments = await BuildUrgentAssignmentsAsync(teacherUserId, classIds, cancellationToken);

        var dto = new TeacherDashboardDto
        {
            TotalStudents = totalStudents,
            ActiveClasses = activeClasses,
            AssignedQuizzes = assignedQuizzes,
            SessionsThisWeek = sessionsThisWeek,
            UniqueActiveStudentsThisWeek = uniqueActiveStudentsThisWeek,
            RecentActivity = recentActivity,
            Insights = insights,
            UrgentAssignments = urgentAssignments,
        };

        memoryCache.Set(cacheKey, dto, DashboardCacheDuration);
        return dto;
    }

    public async Task<IReadOnlyList<ActivityFeedItemDto>> GetActivityFeedAsync(
        Guid teacherUserId,
        int take = 30,
        CancellationToken cancellationToken = default)
    {
        var assignmentIds = await GetTeacherAssignmentIdsAsync(teacherUserId, cancellationToken);
        return await GetActivityFeedAsync(teacherUserId, take, cancellationToken, assignmentIds);
    }

    private async Task<IReadOnlyList<ActivityFeedItemDto>> GetActivityFeedAsync(
        Guid teacherUserId,
        int take,
        CancellationToken cancellationToken,
        IReadOnlyList<Guid> assignmentIds)
    {
        if (assignmentIds.Count == 0)
        {
            return [];
        }

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps =>
                ps.AssignmentId.HasValue
                && assignmentIds.Contains(ps.AssignmentId.Value)
                && ps.Status == "finished"
                && ps.GuestVisitId == null
                && ps.FinishedAt != null)
            .Include(ps => ps.StudentUser)
            .OrderByDescending(ps => ps.FinishedAt)
            .Take(take)
            .ToListAsync(cancellationToken);

        var quizTitles = await QuizTitleLookup.LoadTitlesAsync(
            dbContext,
            sessions.Select(ps => ps.QuizId),
            cancellationToken);

        var sessionAssignmentIds = sessions
            .Select(ps => ps.AssignmentId!.Value)
            .Distinct()
            .ToList();

        var assignmentTitles = await dbContext.Assignments
            .AsNoTracking()
            .Where(a => sessionAssignmentIds.Contains(a.AssignmentId))
            .ToDictionaryAsync(a => (Guid)a.AssignmentId, a => a.Title, cancellationToken);

        return sessions.Select(ps =>
        {
            var scorePct = ps.ScorePossible > 0
                ? (int)Math.Round(ps.ScoreObtained / ps.ScorePossible * 100)
                : 0;

            return new ActivityFeedItemDto
            {
                PracticeSessionId = ps.PracticeSessionId,
                StudentName = ps.StudentUser?.DisplayName ?? ps.StudentUser?.Email ?? "Unknown",
                StudentAvatarId = ps.StudentUser?.AvatarId,
                QuizTitle = QuizTitleLookup.Resolve(quizTitles, ps.QuizId),
                AssignmentTitle = assignmentTitles.TryGetValue(ps.AssignmentId!.Value, out var t) ? t : null,
                ScorePercent = scorePct,
                Passed = scorePct >= 60,
                CompletedAt = ps.FinishedAt!.Value,
            };
        }).ToList();
    }

    public async Task<ClassAnalyticsDto> GetClassAnalyticsAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var cls = await dbContext.TeacherClasses
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.ClassId == classId && c.TeacherUserId == teacherUserId, cancellationToken)
            ?? throw new Application.Exceptions.AppException("Class not found or you do not own it.", 404);

        var memberCount = await dbContext.ClassMembers
            .AsNoTracking()
            .CountAsync(m => m.ClassId == classId && m.Status == "active", cancellationToken);

        var assignments = await dbContext.Assignments
            .AsNoTracking()
            .Where(a => a.ClassId == classId && a.Status != "archived")
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

        var assignmentIds = assignments.Select(a => a.AssignmentId).ToList();

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.Status == "finished"
                && (ps.ClassId == classId
                    || (ps.AssignmentId.HasValue && assignmentIds.Contains(ps.AssignmentId.Value))))
            .ToListAsync(cancellationToken);

        var avgScore = sessions.Count > 0 && sessions.Any(s => s.ScorePossible > 0)
            ? sessions.Where(s => s.ScorePossible > 0)
                .Average(s => (double)s.ScoreObtained / (double)s.ScorePossible * 100)
            : 0;

        var assignmentSummaries = new List<AssignmentAnalyticsSummaryDto>();
        foreach (var a in assignments)
        {
            var assignSessions = sessions.Where(s => s.AssignmentId == a.AssignmentId).ToList();
            var assignAvg = assignSessions.Count > 0 && assignSessions.Any(s => s.ScorePossible > 0)
                ? (decimal)assignSessions.Where(s => s.ScorePossible > 0)
                    .Average(s => (double)s.ScoreObtained / (double)s.ScorePossible * 100)
                : 0;

            var uniqueCompleted = assignSessions
                .Where(s => s.StudentUserId.HasValue)
                .Select(s => s.StudentUserId!.Value)
                .Distinct()
                .Count();

            assignmentSummaries.Add(new AssignmentAnalyticsSummaryDto
            {
                AssignmentId = a.AssignmentId,
                Title = a.Title,
                CompletedCount = uniqueCompleted,
                TotalMembers = memberCount,
                AverageScore = Math.Round(assignAvg, 1),
            });
        }

        return new ClassAnalyticsDto
        {
            ClassId = cls.ClassId,
            ClassName = cls.Name,
            TotalMembers = memberCount,
            TotalSessions = sessions.Count,
            AverageScore = Math.Round((decimal)avgScore, 1),
            Assignments = assignmentSummaries,
        };
    }

    private async Task<IReadOnlyList<UrgentAssignmentDto>> BuildUrgentAssignmentsAsync(
        Guid teacherUserId,
        IReadOnlyList<Guid> classIds,
        CancellationToken cancellationToken)
    {
        if (classIds.Count == 0)
        {
            return [];
        }

        var now = DateTime.UtcNow;
        var dueThreshold = now.AddDays(3);

        var assignments = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Class)
            .Where(a => classIds.Contains(a.ClassId)
                && a.Status == "active"
                && a.Class.TeacherUserId == teacherUserId)
            .ToListAsync(cancellationToken);

        var memberCounts = await dbContext.ClassMembers
            .AsNoTracking()
            .Where(m => classIds.Contains(m.ClassId) && m.Status == "active")
            .GroupBy(m => m.ClassId)
            .Select(g => new { ClassId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ClassId, x => x.Count, cancellationToken);

        var assignmentIds = assignments.Select(a => a.AssignmentId).ToList();

        var completedByAssignment = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId.HasValue
                && assignmentIds.Contains(ps.AssignmentId.Value)
                && ps.Status == "finished"
                && ps.StudentUserId != null)
            .GroupBy(ps => ps.AssignmentId!.Value)
            .Select(g => new
            {
                AssignmentId = g.Key,
                Students = g.Select(ps => ps.StudentUserId!.Value).Distinct().Count(),
            })
            .ToDictionaryAsync(x => x.AssignmentId, x => x.Students, cancellationToken);

        var urgent = new List<UrgentAssignmentDto>();

        foreach (var a in assignments)
        {
            memberCounts.TryGetValue(a.ClassId, out var totalMembers);
            completedByAssignment.TryGetValue(a.AssignmentId, out var uniqueCompleted);
            var pending = Math.Max(0, totalMembers - uniqueCompleted);

            var isDueSoon = a.DueAt.HasValue && a.DueAt.Value <= dueThreshold && a.DueAt.Value >= now;
            var isOverdue = a.DueAt.HasValue && a.DueAt.Value < now;

            if (pending > 0 && (isDueSoon || isOverdue))
            {
                urgent.Add(new UrgentAssignmentDto
                {
                    AssignmentId = a.AssignmentId,
                    ClassId = a.ClassId,
                    Title = a.Title,
                    ClassName = a.Class.Name,
                    DueAt = a.DueAt,
                    PendingStudents = pending,
                    TotalMembers = totalMembers,
                    UniqueStudentsCompleted = uniqueCompleted,
                });
            }
        }

        return urgent
            .OrderBy(u => u.DueAt ?? DateTime.MaxValue)
            .Take(5)
            .ToList();
    }

    private Task<List<Guid>> GetTeacherAssignmentIdsAsync(
        Guid teacherUserId,
        CancellationToken cancellationToken) =>
        dbContext.Assignments
            .AsNoTracking()
            .Where(a => a.Class.TeacherUserId == teacherUserId && a.Status != "archived")
            .Select(a => a.AssignmentId)
            .ToListAsync(cancellationToken);

    private async Task<IReadOnlyList<TeacherInsightDto>> BuildInsightsAsync(
        Guid teacherUserId,
        CancellationToken cancellationToken,
        IReadOnlyList<Guid>? assignmentIds = null)
    {
        assignmentIds ??= await GetTeacherAssignmentIdsAsync(teacherUserId, cancellationToken);

        if (assignmentIds.Count == 0)
        {
            return [];
        }

        var insights = new List<TeacherInsightDto>();

        var highErrorStats = await dbContext.PracticeQuestionSnapshots
            .AsNoTracking()
            .Where(s =>
                s.PracticeSession.Status == "finished"
                && s.PracticeSession.GuestVisitId == null
                && s.PracticeSession.AssignmentId.HasValue
                && assignmentIds.Contains(s.PracticeSession.AssignmentId.Value))
            .GroupBy(s => s.QuestionId)
            .Select(g => new
            {
                QuestionId = g.Key,
                AttemptsCount = g.Count(),
                IncorrectCount = g.Count(x =>
                    x.AnswerStatus == "answered" && x.IsCorrect != true),
            })
            .Where(x => x.AttemptsCount >= 5
                && (double)x.IncorrectCount / x.AttemptsCount > 0.6)
            .OrderByDescending(x => (double)x.IncorrectCount / x.AttemptsCount)
            .Take(2)
            .ToListAsync(cancellationToken);

        if (highErrorStats.Count > 0)
        {
            var questionIds = highErrorStats.Select(h => h.QuestionId).ToList();
            var questions = await dbContext.Questions
                .IgnoreQueryFilters()
                .AsNoTracking()
                .Where(q => questionIds.Contains(q.QuestionId))
                .ToListAsync(cancellationToken);

            var quizTitles = await QuizTitleLookup.LoadTitlesAsync(
                dbContext,
                questions.Select(q => q.QuizId),
                cancellationToken);

            foreach (var stat in highErrorStats)
            {
                var question = questions.FirstOrDefault(q => q.QuestionId == stat.QuestionId);
                if (question is null)
                {
                    continue;
                }

                var errorRate = ((int)Math.Round(
                    (double)stat.IncorrectCount / stat.AttemptsCount * 100)).ToString();
                var questionPreview = Truncate(question.QuestionText, 80);

                insights.Add(new TeacherInsightDto
                {
                    Type = "high_error_rate",
                    Params = new Dictionary<string, string>
                    {
                        ["errorRate"] = errorRate,
                        ["questionText"] = questionPreview,
                    },
                    QuizId = question.QuizId,
                    QuizTitle = QuizTitleLookup.Resolve(quizTitles, question.QuizId),
                });
            }
        }

        var weekAgo = DateTime.UtcNow.AddDays(-7);
        var mostActive = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.Status == "finished"
                && ps.FinishedAt >= weekAgo
                && ps.GuestVisitId == null
                && ps.AssignmentId.HasValue
                && assignmentIds.Contains(ps.AssignmentId.Value))
            .GroupBy(ps => ps.AssignmentId!.Value)
            .Select(g => new
            {
                AssignmentId = g.Key,
                SessionCount = g.Count(),
                StudentCount = g.Where(ps => ps.StudentUserId != null)
                    .Select(ps => ps.StudentUserId!.Value)
                    .Distinct()
                    .Count(),
            })
            .OrderByDescending(g => g.SessionCount)
            .FirstOrDefaultAsync(cancellationToken);

        if (mostActive is not null && mostActive.SessionCount >= 3)
        {
            var assignmentInfo = await dbContext.Assignments
                .AsNoTracking()
                .Where(a => a.AssignmentId == mostActive.AssignmentId)
                .Select(a => new { a.Title, a.QuizId })
                .FirstOrDefaultAsync(cancellationToken);

            if (assignmentInfo is not null)
            {
                var quizTitles = await QuizTitleLookup.LoadTitlesAsync(
                    dbContext,
                    [assignmentInfo.QuizId],
                    cancellationToken);

                insights.Add(new TeacherInsightDto
                {
                    Type = "most_active_sessions",
                    Params = new Dictionary<string, string>
                    {
                        ["sessionCount"] = mostActive.SessionCount.ToString(),
                        ["studentCount"] = mostActive.StudentCount.ToString(),
                    },
                    QuizId = assignmentInfo.QuizId,
                    AssignmentId = mostActive.AssignmentId,
                    QuizTitle = QuizTitleLookup.Resolve(
                        quizTitles,
                        assignmentInfo.QuizId,
                        assignmentInfo.Title),
                });
            }
        }

        return insights;
    }

    private static string Truncate(string text, int maxLength)
    {
        if (string.IsNullOrEmpty(text) || text.Length <= maxLength)
        {
            return text;
        }

        return text[..maxLength].TrimEnd() + "…";
    }
}
