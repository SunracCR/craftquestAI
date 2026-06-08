using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Student;
using CraftQuest.Application.Services;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class StudentService(CraftQuestDbContext dbContext) : IStudentService
{
    public async Task<IReadOnlyList<StudentClassSummaryDto>> ListMyClassesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        return await (
            from member in dbContext.ClassMembers.AsNoTracking()
            join teacherClass in dbContext.TeacherClasses.AsNoTracking()
                on member.ClassId equals teacherClass.ClassId
            join teacher in dbContext.Users.AsNoTracking()
                on teacherClass.TeacherUserId equals teacher.UserId
            where member.UserId == userId
                && member.Status == "active"
                && teacherClass.Status == "active"
            orderby teacherClass.Name
            select new StudentClassSummaryDto
            {
                ClassId = teacherClass.ClassId,
                Name = teacherClass.Name,
                Description = teacherClass.Description,
                TeacherDisplayName = teacher.DisplayName ?? teacher.Email,
                ActiveAssignmentCount = dbContext.Assignments.Count(
                    a => a.ClassId == teacherClass.ClassId && a.Status == "active"),
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<StudentAssignmentDto>> ListMyAssignmentsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var assignments = await (
            from member in dbContext.ClassMembers.AsNoTracking()
            join teacherClass in dbContext.TeacherClasses.AsNoTracking()
                on member.ClassId equals teacherClass.ClassId
            join assignment in dbContext.Assignments.AsNoTracking()
                on teacherClass.ClassId equals assignment.ClassId
            join quiz in dbContext.Quizzes.AsNoTracking()
                on assignment.QuizId equals quiz.QuizId
            join teacher in dbContext.Users.AsNoTracking()
                on teacherClass.TeacherUserId equals teacher.UserId
            where member.UserId == userId
                && member.Status == "active"
                && teacherClass.Status == "active"
                && assignment.Status != "archived"
               
                && quiz.PublicationStatus == "published"
            orderby assignment.DueAt ?? assignment.CreatedAt descending
            select new
            {
                assignment.AssignmentId,
                assignment.ClassId,
                ClassName = teacherClass.Name,
                assignment.QuizId,
                assignment.Title,
                QuizTitle = quiz.Title,
                assignment.Instructions,
                assignment.Status,
                assignment.StartsAt,
                assignment.DueAt,
                assignment.MaxAttempts,
                assignment.RandomizeQuestions,
                assignment.AllowStudentRandomizeQuestions,
                assignment.ForfeitExitCountsAsAttempt,
                assignment.CreatedAt,
                TeacherDisplayName = teacher.DisplayName ?? teacher.Email,
            })
            .ToListAsync(cancellationToken);

        if (assignments.Count == 0)
        {
            return [];
        }

        var assignmentIds = assignments.Select(a => a.AssignmentId).ToList();
        var attemptCounts = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.StudentUserId == userId
                && ps.AssignmentId.HasValue
                && assignmentIds.Contains(ps.AssignmentId.Value)
                && (ps.Status == "finished" || ps.Status == "forfeited"))
            .GroupBy(ps => ps.AssignmentId!.Value)
            .Select(g => new { AssignmentId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.AssignmentId, x => x.Count, cancellationToken);

        return assignments
            .Select(a => new StudentAssignmentDto
            {
                AssignmentId = a.AssignmentId,
                ClassId = a.ClassId,
                ClassName = a.ClassName,
                QuizId = a.QuizId,
                Title = a.Title,
                QuizTitle = a.QuizTitle,
                Instructions = a.Instructions,
                Status = a.Status,
                StartsAt = a.StartsAt,
                DueAt = a.DueAt,
                MaxAttempts = a.MaxAttempts,
                RandomizeQuestions = a.RandomizeQuestions,
                AllowStudentRandomizeQuestions = a.AllowStudentRandomizeQuestions,
                ForfeitExitCountsAsAttempt = a.ForfeitExitCountsAsAttempt,
                MyAttemptCount = attemptCounts.GetValueOrDefault(a.AssignmentId),
                TeacherDisplayName = a.TeacherDisplayName,
                CreatedAt = a.CreatedAt,
            })
            .ToList();
    }

    public async Task<IReadOnlyList<StudentAssignmentAttemptSummaryDto>> ListMyAssignmentAttemptsAsync(
        Guid userId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await (
            from member in dbContext.ClassMembers.AsNoTracking()
            join teacherClass in dbContext.TeacherClasses.AsNoTracking()
                on member.ClassId equals teacherClass.ClassId
            join assignmentRow in dbContext.Assignments.AsNoTracking()
                on teacherClass.ClassId equals assignmentRow.ClassId
            where member.UserId == userId
                && member.Status == "active"
                && teacherClass.Status == "active"
                && assignmentRow.AssignmentId == assignmentId
                && assignmentRow.Status != "archived"
            select assignmentRow)
            .FirstOrDefaultAsync(cancellationToken);

        if (assignment is null)
        {
            throw new AppException("Assignment not found.", 404);
        }

        var canViewReview = AssignmentAnswerRevealHelper.CanStudentViewCorrectAnswers(assignment);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId
                && ps.StudentUserId == userId
                && (ps.Status == "finished" || ps.Status == "forfeited"))
            .OrderByDescending(ps => ps.FinishedAt ?? ps.StartedAt)
            .Select(ps => new
            {
                ps.PracticeSessionId,
                ps.ScoreObtained,
                ps.ScorePossible,
                ps.Status,
                ps.FinishedAt,
                ps.StartedAt,
                ps.DurationSeconds,
                ps.ShowElapsedTimer,
            })
            .ToListAsync(cancellationToken);

        return sessions
            .Select(s => new StudentAssignmentAttemptSummaryDto
            {
                PracticeSessionId = s.PracticeSessionId,
                ScoreObtained = s.ScoreObtained,
                ScorePossible = s.ScorePossible,
                Status = s.Status,
                FinishedAt = s.FinishedAt,
                StartedAt = s.StartedAt,
                DurationSeconds = s.DurationSeconds,
                ShowElapsedTimer = s.ShowElapsedTimer,
                CanViewDetailedReview = canViewReview,
                AssignmentShowCorrectAnswersMode = assignment.ShowCorrectAnswersMode,
                AssignmentDueAt = assignment.DueAt,
            })
            .ToList();
    }

    public async Task<StudentAssignmentSummaryDto> GetMyAssignmentSummaryAsync(
        Guid userId,
        Guid assignmentId,
        CancellationToken cancellationToken = default)
    {
        var assignment = await (
            from member in dbContext.ClassMembers.AsNoTracking()
            join teacherClass in dbContext.TeacherClasses.AsNoTracking()
                on member.ClassId equals teacherClass.ClassId
            join assignmentRow in dbContext.Assignments.AsNoTracking()
                on teacherClass.ClassId equals assignmentRow.ClassId
            where member.UserId == userId
                && member.Status == "active"
                && teacherClass.Status == "active"
                && assignmentRow.AssignmentId == assignmentId
                && assignmentRow.Status != "archived"
            select assignmentRow)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AppException("Assignment not found.", 404);

        var canViewReview = AssignmentAnswerRevealHelper.CanStudentViewCorrectAnswers(assignment);

        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Where(ps => ps.AssignmentId == assignmentId
                && ps.StudentUserId == userId
                && ps.Status == "finished")
            .Include(ps => ps.QuestionSnapshots)
            .OrderBy(ps => ps.FinishedAt ?? ps.StartedAt)
            .ToListAsync(cancellationToken);

        var percentages = sessions
            .Select(s => s.ScorePossible > 0
                ? Math.Round(s.ScoreObtained / s.ScorePossible * 100, 2)
                : 0m)
            .ToList();

        var attemptTrend = sessions
            .Select((s, index) => new AssignmentAttemptTrendDto
            {
                AttemptNumber = index + 1,
                Percentage = s.ScorePossible > 0
                    ? Math.Round(s.ScoreObtained / s.ScorePossible * 100, 2)
                    : 0,
                FinishedAt = s.FinishedAt ?? s.StartedAt,
                PracticeSessionId = s.PracticeSessionId,
            })
            .ToList();

        decimal? scoreTrend = null;
        if (percentages.Count >= 2)
        {
            scoreTrend = percentages[^1] - percentages[0];
        }

        IReadOnlyList<QuestionAnalyticsDto> hardQuestions = [];
        if (canViewReview)
        {
            var questions = await dbContext.Questions
                .AsNoTracking()
                .Where(q => q.QuizId == assignment.QuizId)
                .OrderBy(q => q.SortOrder)
                .Include(q => q.AnswerOptions.Where(o => o.IsActive))
                .Include(q => q.CorrectAnswerOptions)
                .ToListAsync(cancellationToken);

            var questionStats = new Dictionary<Guid, (int Attempts, int Incorrect)>();
            foreach (var session in sessions)
            {
                foreach (var snapshot in session.QuestionSnapshots)
                {
                    if (!questionStats.TryGetValue(snapshot.QuestionId, out var stats))
                    {
                        stats = (0, 0);
                    }

                    stats.Attempts++;
                    if (snapshot.AnswerStatus == "answered" && snapshot.IsCorrect != true)
                    {
                        stats.Incorrect++;
                    }

                    questionStats[snapshot.QuestionId] = stats;
                }
            }

            hardQuestions = questions
                .Select(q =>
                {
                    questionStats.TryGetValue(q.QuestionId, out var stats);
                    var attempts = stats.Attempts;
                    var errorRate = attempts > 0
                        ? Math.Round((decimal)stats.Incorrect / attempts * 100, 2)
                        : 0m;

                    var correctIds = q.CorrectAnswerOptions
                        .Select(c => c.AnswerOptionId)
                        .ToHashSet();

                    return new QuestionAnalyticsDto
                    {
                        QuestionId = q.QuestionId,
                        QuestionText = q.QuestionText,
                        AttemptsCount = attempts,
                        CorrectCount = attempts - stats.Incorrect,
                        IncorrectCount = stats.Incorrect,
                        OmittedCount = 0,
                        AnswerOptions = q.AnswerOptions
                            .OrderBy(o => o.DefaultSortOrder)
                            .Select(o => new AnswerOptionAnalyticsDto
                            {
                                AnswerOptionId = o.AnswerOptionId,
                                StableKey = o.StableKey,
                                Text = o.AnswerText,
                                IsCorrect = correctIds.Contains(o.AnswerOptionId),
                                SelectedCount = 0,
                                SelectionRate = errorRate,
                            })
                            .ToList(),
                    };
                })
                .Where(q => q.AttemptsCount > 0 && q.IncorrectCount > 0)
                .OrderByDescending(q => q.IncorrectCount / (double)Math.Max(1, q.AttemptsCount))
                .Take(3)
                .ToList();
        }

        return new StudentAssignmentSummaryDto
        {
            AssignmentId = assignmentId,
            AssignmentTitle = assignment.Title,
            FinishedAttempts = sessions.Count,
            BestPercentage = percentages.Count > 0 ? percentages.Max() : null,
            LastPercentage = percentages.Count > 0 ? percentages[^1] : null,
            AveragePercentage = percentages.Count > 0
                ? Math.Round(percentages.Average(), 2)
                : null,
            ScoreTrend = scoreTrend,
            AttemptTrend = attemptTrend,
            HardQuestionsForMe = hardQuestions,
            CanViewDetailedReview = canViewReview,
            AssignmentShowCorrectAnswersMode = assignment.ShowCorrectAnswersMode,
            AssignmentDueAt = assignment.DueAt,
        };
    }
}
