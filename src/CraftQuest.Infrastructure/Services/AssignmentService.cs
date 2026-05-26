using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Teacher;
using CraftQuest.Application.Services;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class AssignmentService(
    CraftQuestDbContext dbContext) : IAssignmentService
{
    public async Task<AssignmentSummaryDto> CreateAsync(
        Guid teacherUserId,
        Guid classId,
        CreateAssignmentRequest request,
        CancellationToken cancellationToken = default)
    {
        var owns = await dbContext.TeacherClasses.AnyAsync(
            c => c.ClassId == classId && c.TeacherUserId == teacherUserId && c.Status == "active",
            cancellationToken);

        if (!owns)
            throw new AppException("Class not found or you do not own it.", 404);

        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == request.QuizId && q.CreatedByUserId == teacherUserId, cancellationToken)
            ?? throw new AppException("Quiz not found or you do not own it.", 404);

        var validModes = new[] { "never", "after_attempt", "after_due_date", "teacher_only" };
        var mode = request.ShowCorrectAnswersMode;
        if (!validModes.Contains(mode))
            throw new AppException("Invalid ShowCorrectAnswersMode value.", 400);

        var entity = new Assignment
        {
            AssignmentId = Guid.NewGuid(),
            ClassId = classId,
            QuizId = request.QuizId,
            CreatedByUserId = teacherUserId,
            Title = request.Title.Trim(),
            Instructions = request.Instructions?.Trim(),
            StartsAt = AssignmentDateHelper.NormalizeToUtcDate(request.StartsAt),
            DueAt = AssignmentDateHelper.NormalizeToUtcDate(request.DueAt),
            MaxAttempts = request.MaxAttempts,
            ShowCorrectAnswersMode = mode,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.Assignments.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        var memberCount = await dbContext.ClassMembers
            .CountAsync(m => m.ClassId == classId && m.Status == "active", cancellationToken);

        return new AssignmentSummaryDto
        {
            AssignmentId = entity.AssignmentId,
            ClassId = entity.ClassId,
            QuizId = entity.QuizId,
            Title = entity.Title,
            QuizTitle = quiz.Title,
            Status = entity.Status,
            ShowCorrectAnswersMode = entity.ShowCorrectAnswersMode,
            StartsAt = entity.StartsAt,
            DueAt = entity.DueAt,
            MaxAttempts = entity.MaxAttempts,
            CompletedCount = 0,
            TotalMembers = memberCount,
            CreatedAt = entity.CreatedAt,
        };
    }

    public async Task<IReadOnlyList<AssignmentSummaryDto>> ListByClassAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default)
    {
        var owns = await dbContext.TeacherClasses.AnyAsync(
            c => c.ClassId == classId && c.TeacherUserId == teacherUserId && c.Status == "active",
            cancellationToken);

        if (!owns)
            throw new AppException("Class not found or you do not own it.", 404);

        var memberCount = await dbContext.ClassMembers
            .CountAsync(m => m.ClassId == classId && m.Status == "active", cancellationToken);

        var assignments = await dbContext.Assignments
            .AsNoTracking()
            .Where(a => a.ClassId == classId && a.Status != "archived")
            .Include(a => a.Quiz)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

        var result = new List<AssignmentSummaryDto>(assignments.Count);
        foreach (var a in assignments)
        {
            var completed = await CountUniqueStudentsCompletedAsync(a.AssignmentId, cancellationToken);

            result.Add(new AssignmentSummaryDto
            {
                AssignmentId = a.AssignmentId,
                ClassId = a.ClassId,
                QuizId = a.QuizId,
                Title = a.Title,
                QuizTitle = a.Quiz.Title,
                Status = a.Status,
                ShowCorrectAnswersMode = a.ShowCorrectAnswersMode,
                StartsAt = a.StartsAt,
                DueAt = a.DueAt,
                MaxAttempts = a.MaxAttempts,
                CompletedCount = completed,
                TotalMembers = memberCount,
                CreatedAt = a.CreatedAt,
            });
        }

        return result;
    }

    public async Task<AssignmentDetailDto> GetDetailAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Quiz)
            .Include(a => a.Class)
            .FirstOrDefaultAsync(a => a.AssignmentId == assignmentId, cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (assignment.Class.TeacherUserId != teacherUserId)
            throw new AppException("Assignment not found.", 404);

        var memberCount = await dbContext.ClassMembers
            .CountAsync(m => m.ClassId == assignment.ClassId && m.Status == "active", cancellationToken);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId && ps.Status == "finished")
            .Include(ps => ps.StudentUser)
            .OrderByDescending(ps => ps.FinishedAt)
            .ToListAsync(cancellationToken);

        var attempts = sessions.Select(ps => new AssignmentAttemptDto
        {
            PracticeSessionId = ps.PracticeSessionId,
            StudentUserId = ps.StudentUserId!.Value,
            StudentName = ps.StudentUser?.DisplayName ?? ps.StudentUser?.Email ?? "Unknown",
            StudentAvatarId = ps.StudentUser?.AvatarId,
            ScoreObtained = ps.ScoreObtained,
            ScorePossible = ps.ScorePossible,
            Percentage = ps.ScorePossible > 0
                ? (int)Math.Round(ps.ScoreObtained / ps.ScorePossible * 100)
                : 0,
            FinishedAt = ps.FinishedAt!.Value,
        }).ToList();

        return new AssignmentDetailDto
        {
            AssignmentId = assignment.AssignmentId,
            ClassId = assignment.ClassId,
            QuizId = assignment.QuizId,
            Title = assignment.Title,
            Instructions = assignment.Instructions,
            QuizTitle = assignment.Quiz.Title,
            Status = assignment.Status,
            ShowCorrectAnswersMode = assignment.ShowCorrectAnswersMode,
            StartsAt = assignment.StartsAt,
            DueAt = assignment.DueAt,
            MaxAttempts = assignment.MaxAttempts,
            CompletedCount = attempts.Select(a => a.StudentUserId).Distinct().Count(),
            TotalMembers = memberCount,
            CreatedAt = assignment.CreatedAt,
            Attempts = attempts,
        };
    }

    public async Task<AssignmentAnalyticsDto> GetAssignmentAnalyticsAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Quiz)
            .Include(a => a.Class)
            .FirstOrDefaultAsync(a => a.AssignmentId == assignmentId, cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (assignment.Class.TeacherUserId != teacherUserId)
            throw new AppException("Assignment not found.", 404);

        var members = await dbContext.ClassMembers
            .AsNoTracking()
            .Where(m => m.ClassId == assignment.ClassId && m.Status == "active")
            .Include(m => m.User)
            .ToListAsync(cancellationToken);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId && ps.Status == "finished")
            .Include(ps => ps.QuestionSnapshots)
            .OrderByDescending(ps => ps.FinishedAt)
            .ToListAsync(cancellationToken);

        var students = BuildStudentProgress(members, sessions);
        var uniqueCompleted = students.Count(s => s.HasCompleted);
        var totalMembers = members.Count;

        var bestScores = students
            .Where(s => s.BestScore.HasValue)
            .Select(s => s.BestScore!.Value)
            .ToList();

        var averageScore = bestScores.Count > 0
            ? Math.Round(bestScores.Average(), 1)
            : 0m;

        decimal? medianScore = null;
        if (bestScores.Count > 0)
        {
            var ordered = bestScores.OrderBy(x => x).ToList();
            var mid = ordered.Count / 2;
            medianScore = ordered.Count % 2 == 0
                ? Math.Round((ordered[mid - 1] + ordered[mid]) / 2, 1)
                : Math.Round(ordered[mid], 1);
        }

        var completionRate = totalMembers > 0
            ? Math.Round((decimal)uniqueCompleted / totalMembers * 100, 1)
            : 0m;

        var hardQuestions = await BuildHardQuestionsAsync(assignment.QuizId, sessions, cancellationToken);
        var distribution = BuildScoreDistribution(students);

        return new AssignmentAnalyticsDto
        {
            AssignmentId = assignment.AssignmentId,
            ClassId = assignment.ClassId,
            Title = assignment.Title,
            ClassName = assignment.Class.Name,
            TotalMembers = totalMembers,
            UniqueStudentsCompleted = uniqueCompleted,
            CompletionRate = completionRate,
            AverageScore = averageScore,
            MedianScore = medianScore,
            TotalSessions = sessions.Count,
            Students = students,
            HardQuestions = hardQuestions,
            ScoreDistribution = distribution,
        };
    }

    public async Task<AssignmentCompletionDto> GetCompletionAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await dbContext.Assignments
            .AsNoTracking()
            .Include(a => a.Class)
            .FirstOrDefaultAsync(a => a.AssignmentId == assignmentId, cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (assignment.Class.TeacherUserId != teacherUserId)
            throw new AppException("Assignment not found.", 404);

        var members = await dbContext.ClassMembers
            .AsNoTracking()
            .Where(m => m.ClassId == assignment.ClassId && m.Status == "active")
            .Include(m => m.User)
            .ToListAsync(cancellationToken);

        var sessionsByStudent = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId && ps.Status == "finished")
            .GroupBy(ps => ps.StudentUserId)
            .Select(g => new
            {
                StudentUserId = g.Key,
                Count = g.Count(),
                Best = g.Max(ps => ps.ScorePossible > 0
                    ? (int?)(int)(ps.ScoreObtained / ps.ScorePossible * 100)
                    : null),
            })
            .ToListAsync(cancellationToken);

        var sessionMap = sessionsByStudent
            .Where(s => s.StudentUserId.HasValue)
            .ToDictionary(s => s.StudentUserId!.Value);

        var progress = members.Select(m =>
        {
            sessionMap.TryGetValue(m.UserId, out var stats);
            return new AssignmentMemberProgressDto
            {
                UserId = m.UserId,
                DisplayName = m.User.DisplayName ?? m.User.Email,
                AvatarId = m.User.AvatarId,
                HasCompleted = stats is not null,
                BestScorePercent = stats?.Best,
                AttemptCount = stats?.Count ?? 0,
            };
        }).OrderByDescending(p => p.HasCompleted).ThenBy(p => p.DisplayName).ToList();

        return new AssignmentCompletionDto
        {
            CompletedCount = progress.Count(p => p.HasCompleted),
            TotalMembers = members.Count,
            Members = progress,
        };
    }

    public async Task CloseAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await LoadOwnedAssignmentAsync(teacherUserId, assignmentId, cancellationToken);
        assignment.Status = "closed";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ArchiveAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await LoadOwnedAssignmentAsync(teacherUserId, assignmentId, cancellationToken);
        assignment.Status = "archived";
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<AssignmentDetailDto> UpdateAsync(
        Guid teacherUserId,
        Guid assignmentId,
        UpdateAssignmentRequest request,
        CancellationToken cancellationToken = default)
    {
        var assignment = await LoadOwnedAssignmentAsync(teacherUserId, assignmentId, cancellationToken);

        if (assignment.Status != "active")
        {
            throw new AppException(
                "Only active assignments can be edited.",
                400,
                errorCode: "ASSIGNMENT_NOT_EDITABLE");
        }

        var title = request.Title.Trim();
        if (string.IsNullOrEmpty(title))
        {
            throw new AppException("Assignment title is required.", 400);
        }

        var validModes = new[] { "never", "after_attempt", "after_due_date", "teacher_only" };
        var mode = request.ShowCorrectAnswersMode;
        if (!validModes.Contains(mode))
        {
            throw new AppException("Invalid ShowCorrectAnswersMode value.", 400);
        }

        if (!AssignmentDateHelper.IsValidDateRange(request.StartsAt, request.DueAt))
        {
            throw new AppException(
                "Due date cannot be before the start date.",
                400,
                errorCode: "ASSIGNMENT_INVALID_DATE_RANGE");
        }

        if (request.MaxAttempts is < 1)
        {
            throw new AppException("Max attempts must be at least 1.", 400);
        }

        if (request.MaxAttempts.HasValue)
        {
            var attemptCounts = await dbContext.PracticeSessions
                .AsNoTracking()
                .Where(ps => ps.AssignmentId == assignmentId
                    && ps.Status == "finished"
                    && ps.StudentUserId != null)
                .GroupBy(ps => ps.StudentUserId)
                .Select(g => g.Count())
                .ToListAsync(cancellationToken);

            var maxExistingAttempts = attemptCounts.Count == 0 ? 0 : attemptCounts.Max();

            if (request.MaxAttempts.Value < maxExistingAttempts)
            {
                throw new AppException(
                    "Max attempts cannot be lower than existing student attempts.",
                    400,
                    errorCode: "ASSIGNMENT_MAX_ATTEMPTS_BELOW_EXISTING");
            }
        }

        assignment.Title = title;
        assignment.Instructions = string.IsNullOrWhiteSpace(request.Instructions)
            ? null
            : request.Instructions.Trim();
        assignment.StartsAt = AssignmentDateHelper.NormalizeToUtcDate(request.StartsAt);
        assignment.DueAt = AssignmentDateHelper.NormalizeToUtcDate(request.DueAt);
        assignment.MaxAttempts = request.MaxAttempts;
        assignment.ShowCorrectAnswersMode = mode;

        await dbContext.SaveChangesAsync(cancellationToken);

        return await GetDetailAsync(teacherUserId, assignmentId, cancellationToken);
    }

    private async Task<Assignment> LoadOwnedAssignmentAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var assignment = await dbContext.Assignments
            .Include(a => a.Class)
            .FirstOrDefaultAsync(a => a.AssignmentId == assignmentId, cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        if (assignment.Class.TeacherUserId != teacherUserId)
            throw new AppException("Assignment not found.", 404);

        return assignment;
    }

    private async Task<int> CountUniqueStudentsCompletedAsync(
        Guid assignmentId,
        CancellationToken cancellationToken) =>
        await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId
                && ps.Status == "finished"
                && ps.StudentUserId != null)
            .Select(ps => ps.StudentUserId!.Value)
            .Distinct()
            .CountAsync(cancellationToken);

    private static List<AssignmentStudentProgressDto> BuildStudentProgress(
        IReadOnlyList<ClassMember> members,
        IReadOnlyList<PracticeSession> sessions)
    {
        var byStudent = sessions
            .Where(s => s.StudentUserId.HasValue)
            .GroupBy(s => s.StudentUserId!.Value)
            .ToDictionary(g => g.Key, g => g.OrderBy(s => s.FinishedAt ?? s.StartedAt).ToList());

        return members.Select(m =>
        {
            byStudent.TryGetValue(m.UserId, out var studentSessions);
            studentSessions ??= [];

            decimal? best = null;
            decimal? last = null;
            decimal? trend = null;
            DateTime? lastAt = null;
            Guid? lastSessionId = null;

            if (studentSessions.Count > 0)
            {
                var percentages = studentSessions
                    .Select(s => s.ScorePossible > 0
                        ? Math.Round(s.ScoreObtained / s.ScorePossible * 100, 2)
                        : 0m)
                    .ToList();

                best = percentages.Max();
                last = percentages[^1];
                trend = percentages.Count >= 2 ? last - percentages[0] : null;

                var lastSession = studentSessions[^1];
                lastAt = lastSession.FinishedAt ?? lastSession.StartedAt;
                lastSessionId = lastSession.PracticeSessionId;
            }

            return new AssignmentStudentProgressDto
            {
                UserId = m.UserId,
                DisplayName = m.User.DisplayName ?? m.User.Email,
                AvatarId = m.User.AvatarId,
                HasCompleted = studentSessions.Count > 0,
                AttemptCount = studentSessions.Count,
                BestScore = best,
                LastScore = last,
                ScoreTrend = trend,
                LastAttemptAt = lastAt,
                LastPracticeSessionId = lastSessionId,
            };
        })
        .OrderBy(s => s.HasCompleted)
        .ThenByDescending(s => s.BestScore ?? -1)
        .ThenBy(s => s.DisplayName)
        .ToList();
    }

    private static IReadOnlyList<ScoreDistributionBucketDto> BuildScoreDistribution(
        IReadOnlyList<AssignmentStudentProgressDto> students)
    {
        var buckets = new[]
        {
            (0, 20),
            (21, 40),
            (41, 60),
            (61, 80),
            (81, 100),
        };

        return buckets.Select(b =>
        {
            var count = students.Count(s =>
                s.BestScore.HasValue
                && s.BestScore.Value >= b.Item1
                && s.BestScore.Value <= b.Item2);

            return new ScoreDistributionBucketDto
            {
                MinPercent = b.Item1,
                MaxPercent = b.Item2,
                StudentCount = count,
            };
        }).ToList();
    }

    private async Task<IReadOnlyList<AssignmentQuestionDifficultyDto>> BuildHardQuestionsAsync(
        Guid quizId,
        IReadOnlyList<PracticeSession> sessions,
        CancellationToken cancellationToken)
    {
        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId && q.DeletedAt == null)
            .OrderBy(q => q.SortOrder)
            .ToListAsync(cancellationToken);

        var stats = new Dictionary<Guid, (int Attempts, int Incorrect)>();

        foreach (var session in sessions)
        {
            foreach (var snapshot in session.QuestionSnapshots)
            {
                if (!stats.TryGetValue(snapshot.QuestionId, out var s))
                {
                    s = (0, 0);
                }

                s.Attempts++;
                if (snapshot.AnswerStatus == "answered" && snapshot.IsCorrect != true)
                {
                    s.Incorrect++;
                }

                stats[snapshot.QuestionId] = s;
            }
        }

        return questions
            .Select(q =>
            {
                stats.TryGetValue(q.QuestionId, out var s);
                var attempts = s.Attempts;
                var errorRate = attempts > 0
                    ? Math.Round((decimal)s.Incorrect / attempts * 100, 1)
                    : 0m;

                return new AssignmentQuestionDifficultyDto
                {
                    QuestionId = q.QuestionId,
                    QuestionText = q.QuestionText,
                    DisplayOrder = q.SortOrder,
                    AttemptsCount = attempts,
                    ErrorRate = errorRate,
                };
            })
            .Where(q => q.AttemptsCount > 0)
            .OrderByDescending(q => q.ErrorRate)
            .ThenBy(q => q.DisplayOrder)
            .Take(5)
            .ToList();
    }
}
