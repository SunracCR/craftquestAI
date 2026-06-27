using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Practice;

internal static class PracticeQuestionLoader
{
    public static async Task<List<Question>> LoadForQuizAsync(
        CraftQuestDbContext dbContext,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Questions
            .AsNoTracking()
            .AsSplitQuery()
            .Include(q => q.QuestionType)
            .Include(q => q.AnswerOptions.Where(o => o.IsActive))
            .Include(q => q.CorrectAnswerOptions)
            .Include(q => q.Justification!)
                .ThenInclude(j => j.Sources)
            .Where(q => q.QuizId == quizId)
            .OrderBy(q => q.SortOrder)
            .ToListAsync(cancellationToken);
    }
}
