using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Application.Services.Quizzes;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services.Quizzes;

internal static class QuestionJustificationWriter
{
    public static async Task ApplyAsync(
        CraftQuestDbContext dbContext,
        Question question,
        QuestionJustificationInput? input,
        bool generatedByAi,
        CancellationToken cancellationToken = default)
    {
        var text = input?.Text?.Trim();
        if (string.IsNullOrWhiteSpace(text))
        {
            if (question.Justification is not null)
            {
                dbContext.QuestionJustifications.Remove(question.Justification);
                question.Justification = null;
            }

            return;
        }

        var status = generatedByAi ? "ai_generated" : "approved";
        var now = DateTime.UtcNow;

        if (question.Justification is null)
        {
            question.Justification = new QuestionJustification
            {
                QuestionJustificationId = Guid.NewGuid(),
                QuestionId = question.QuestionId,
                CreatedAt = now,
            };
            dbContext.QuestionJustifications.Add(question.Justification);
        }

        var justification = question.Justification;
        justification.JustificationText = text;
        justification.Status = status;
        justification.GeneratedByAi = generatedByAi;
        justification.UpdatedAt = now;

        var existingSources = await dbContext.Set<QuestionJustificationSource>()
            .Where(s => s.QuestionJustificationId == justification.QuestionJustificationId)
            .ToListAsync(cancellationToken);
        if (existingSources.Count > 0)
        {
            dbContext.Set<QuestionJustificationSource>().RemoveRange(existingSources);
        }

        var sources = input?.Sources ?? [];
        var anyPrimary = sources.Any(s => s.IsPrimary);
        var index = 0;
        foreach (var source in sources)
        {
            var url = QuestionJustificationMapper.ResolveSourceUrl(source);
            if (string.IsNullOrWhiteSpace(url))
            {
                continue;
            }

            dbContext.Set<QuestionJustificationSource>().Add(new QuestionJustificationSource
            {
                JustificationSourceId = Guid.NewGuid(),
                QuestionJustificationId = justification.QuestionJustificationId,
                SourceTitle = source.Title?.Trim(),
                SourceUrl = url,
                SourceProvider = source.Provider?.Trim(),
                Snippet = source.Snippet?.Trim(),
                SourcePageNumber = source.PageNumber,
                StudyMaterialId = source.StudyMaterialId,
                RetrievedAt = now,
                IsPrimary = source.IsPrimary || (!anyPrimary && index == 0),
            });
            index++;
        }
    }
}
