using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class QuizPracticePreferenceService(
    CraftQuestDbContext dbContext,
    IShareCodeService shareCodeService) : IQuizPracticePreferenceService
{
    public async Task<QuizPracticePreferenceDto> GetAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanAccessQuizAsync(userId, quizId, cancellationToken);

        var preference = await dbContext.UserQuizPracticePreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(
                p => p.UserId == userId && p.QuizId == quizId,
                cancellationToken);

        return Map(quizId, preference);
    }

    public async Task<QuizPracticePreferenceDto> UpsertAsync(
        Guid userId,
        Guid quizId,
        UpsertQuizPracticePreferenceRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanAccessQuizAsync(userId, quizId, cancellationToken);

        var preference = await dbContext.UserQuizPracticePreferences
            .FirstOrDefaultAsync(
                p => p.UserId == userId && p.QuizId == quizId,
                cancellationToken);

        var now = DateTime.UtcNow;
        if (preference is null)
        {
            preference = new UserQuizPracticePreference
            {
                UserId = userId,
                QuizId = quizId,
                RandomizeQuestions = request.RandomizeQuestions,
                ShowElapsedTimer = request.ShowElapsedTimer,
                UpdatedAt = now,
            };
            dbContext.UserQuizPracticePreferences.Add(preference);
        }
        else
        {
            preference.RandomizeQuestions = request.RandomizeQuestions;
            preference.ShowElapsedTimer = request.ShowElapsedTimer;
            preference.UpdatedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(quizId, preference);
    }

    private async Task EnsureCanAccessQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId == userId)
        {
            return;
        }

        var hasAccess = await shareCodeService.HasQuizAccessAsync(
            userId,
            quizId,
            cancellationToken);
        if (!hasAccess)
        {
            throw new AppException(
                "You do not have access to this quiz.",
                403);
        }
    }

    private static QuizPracticePreferenceDto Map(
        Guid quizId,
        UserQuizPracticePreference? preference) =>
        new()
        {
            QuizId = quizId,
            RandomizeQuestions = preference?.RandomizeQuestions ?? false,
            ShowElapsedTimer = preference?.ShowElapsedTimer ?? true,
        };
}
