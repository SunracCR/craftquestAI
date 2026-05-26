using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class AnalyticsService(CraftQuestDbContext dbContext) : IAnalyticsService
{
    public async Task RecordFinishedPracticeSessionAsync(
        PracticeSession session,
        CancellationToken cancellationToken = default)
    {
        // Guest sessions are ephemeral; skip analytics.
        if (session.GuestVisitId.HasValue)
        {
            return;
        }

        foreach (var questionSnapshot in session.QuestionSnapshots)
        {
            var questionStats = await dbContext.QuestionStats
                .FirstOrDefaultAsync(s => s.QuestionId == questionSnapshot.QuestionId, cancellationToken);

            if (questionStats is null)
            {
                questionStats = new QuestionStats
                {
                    QuestionId = questionSnapshot.QuestionId,
                    UpdatedAt = DateTime.UtcNow,
                };
                dbContext.QuestionStats.Add(questionStats);
            }

            questionStats.AttemptsCount++;
            switch (questionSnapshot.AnswerStatus)
            {
                case "answered" when questionSnapshot.IsCorrect == true:
                    questionStats.CorrectCount++;
                    break;
                case "answered":
                    questionStats.IncorrectCount++;
                    break;
                default:
                    questionStats.OmittedCount++;
                    break;
            }

            if (questionSnapshot.TimeSpentSeconds.HasValue)
            {
                var previousTotal = (questionStats.AverageTimeSeconds ?? 0) *
                                    (questionStats.AttemptsCount - 1);
                questionStats.AverageTimeSeconds = Math.Round(
                    (previousTotal + questionSnapshot.TimeSpentSeconds.Value) /
                    questionStats.AttemptsCount,
                    2);
            }

            questionStats.UpdatedAt = DateTime.UtcNow;

            foreach (var answerSnapshot in questionSnapshot.AnswerOptionSnapshots)
            {
                if (!answerSnapshot.WasSelected)
                {
                    continue;
                }

                var optionStats = await dbContext.AnswerOptionStats
                    .FirstOrDefaultAsync(
                        s => s.AnswerOptionId == answerSnapshot.AnswerOptionId,
                        cancellationToken);

                if (optionStats is null)
                {
                    optionStats = new AnswerOptionStats
                    {
                        AnswerOptionId = answerSnapshot.AnswerOptionId,
                        QuestionId = questionSnapshot.QuestionId,
                    };
                    dbContext.AnswerOptionStats.Add(optionStats);
                }

                optionStats.SelectedCount++;
                optionStats.LastSelectedAt = answerSnapshot.SelectedAt ?? DateTime.UtcNow;
            }
        }
    }

    public async Task<QuizAnalyticsDto> GetQuizAnalyticsAsync(
        Guid teacherUserId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId && q.DeletedAt == null, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId != teacherUserId)
        {
            throw new AppException("You do not have permission to view analytics for this quiz.", 403);
        }

        var totalSessions = await dbContext.PracticeSessions
            .CountAsync(
                s => s.QuizId == quizId && s.Status == "finished",
                cancellationToken);

        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId && q.DeletedAt == null)
            .OrderBy(q => q.SortOrder)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .ToListAsync(cancellationToken);

        var questionIds = questions.Select(q => q.QuestionId).ToList();
        var questionStats = await dbContext.QuestionStats
            .AsNoTracking()
            .Where(s => questionIds.Contains(s.QuestionId))
            .ToDictionaryAsync(s => s.QuestionId, cancellationToken);

        var optionIds = questions.SelectMany(q => q.AnswerOptions.Select(o => o.AnswerOptionId)).ToList();
        var optionStats = await dbContext.AnswerOptionStats
            .AsNoTracking()
            .Where(s => optionIds.Contains(s.AnswerOptionId))
            .ToDictionaryAsync(s => s.AnswerOptionId, cancellationToken);

        var correctIdsByQuestion = questions.ToDictionary(
            q => q.QuestionId,
            q => q.CorrectAnswerOptions.Select(c => c.AnswerOptionId).ToHashSet());

        var questionDtos = questions.Select(q =>
        {
            questionStats.TryGetValue(q.QuestionId, out var stats);
            var attempts = stats?.AttemptsCount ?? 0;

            var options = q.AnswerOptions
                .OrderBy(o => o.DefaultSortOrder)
                .Select(o =>
                {
                    optionStats.TryGetValue(o.AnswerOptionId, out var oStats);
                    var selected = oStats?.SelectedCount ?? 0;
                    var isCorrect = correctIdsByQuestion[q.QuestionId].Contains(o.AnswerOptionId);

                    return new AnswerOptionAnalyticsDto
                    {
                        AnswerOptionId = o.AnswerOptionId,
                        StableKey = o.StableKey,
                        Text = o.AnswerText,
                        IsCorrect = isCorrect,
                        SelectedCount = selected,
                        SelectionRate = attempts > 0
                            ? Math.Round((decimal)selected / attempts * 100, 2)
                            : 0,
                    };
                })
                .ToList();

            return new QuestionAnalyticsDto
            {
                QuestionId = q.QuestionId,
                QuestionText = q.QuestionText,
                AttemptsCount = attempts,
                CorrectCount = stats?.CorrectCount ?? 0,
                IncorrectCount = stats?.IncorrectCount ?? 0,
                OmittedCount = stats?.OmittedCount ?? 0,
                AnswerOptions = options,
            };
        }).ToList();

        return new QuizAnalyticsDto
        {
            QuizId = quizId,
            TotalPracticeSessions = totalSessions,
            Questions = questionDtos,
        };
    }
}
