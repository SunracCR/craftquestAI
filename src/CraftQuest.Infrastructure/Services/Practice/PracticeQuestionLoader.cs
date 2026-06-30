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
        var questionRows = await dbContext.Questions
            .AsNoTracking()
            .Where(q => q.QuizId == quizId)
            .OrderBy(q => q.SortOrder)
            .Select(q => new QuestionRow
            {
                QuestionId = q.QuestionId,
                QuizId = q.QuizId,
                QuizSectionId = q.QuizSectionId,
                QuestionTypeId = q.QuestionTypeId,
                QuestionText = q.QuestionText,
                Points = q.Points,
                SortOrder = q.SortOrder,
                Difficulty = q.Difficulty,
                ExplanationVisibility = q.ExplanationVisibility,
                RandomizeAnswerOptions = q.RandomizeAnswerOptions,
                ScoringPolicy = q.ScoringPolicy,
                ReviewStatus = q.ReviewStatus,
                IsGeneratedByAi = q.IsGeneratedByAi,
                CreatedByUserId = q.CreatedByUserId,
                CreatedAt = q.CreatedAt,
                UpdatedAt = q.UpdatedAt,
                DeletedAt = q.DeletedAt,
                QuestionTypeCode = q.QuestionType.Code,
                QuestionTypeSupportsMultiple = q.QuestionType.SupportsMultipleCorrectAnswers,
            })
            .ToListAsync(cancellationToken);

        if (questionRows.Count == 0)
        {
            return [];
        }

        var questionIds = questionRows.Select(q => q.QuestionId).ToList();

        var answerOptions = await dbContext.QuestionAnswerOptions
            .AsNoTracking()
            .Where(o => o.IsActive && questionIds.Contains(o.QuestionId))
            .OrderBy(o => o.QuestionId)
            .ThenBy(o => o.DefaultSortOrder)
            .ToListAsync(cancellationToken);

        var correctOptions = await dbContext.QuestionCorrectAnswerOptions
            .AsNoTracking()
            .Where(c => questionIds.Contains(c.QuestionId))
            .ToListAsync(cancellationToken);

        var justifications = await dbContext.QuestionJustifications
            .AsNoTracking()
            .Where(j => questionIds.Contains(j.QuestionId))
            .ToListAsync(cancellationToken);

        var justificationIds = justifications
            .Select(j => j.QuestionJustificationId)
            .ToList();

        var justificationSources = justificationIds.Count == 0
            ? []
            : await dbContext.QuestionJustificationSources
                .AsNoTracking()
                .Where(s => justificationIds.Contains(s.QuestionJustificationId))
                .OrderBy(s => s.QuestionJustificationId)
                .ThenByDescending(s => s.IsPrimary)
                .ThenBy(s => s.RetrievedAt)
                .ToListAsync(cancellationToken);

        var optionsByQuestion = answerOptions
            .GroupBy(o => o.QuestionId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var correctByQuestion = correctOptions
            .GroupBy(c => c.QuestionId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var justificationByQuestion = justifications
            .ToDictionary(j => j.QuestionId);

        var sourcesByJustification = justificationSources
            .GroupBy(s => s.QuestionJustificationId)
            .ToDictionary(g => g.Key, g => g.ToList());

        return questionRows
            .Select(row =>
            {
                justificationByQuestion.TryGetValue(row.QuestionId, out var justification);
                if (justification is not null
                    && sourcesByJustification.TryGetValue(justification.QuestionJustificationId, out var sources))
                {
                    justification.Sources = sources;
                }

                return new Question
                {
                    QuestionId = row.QuestionId,
                    QuizId = row.QuizId,
                    QuizSectionId = row.QuizSectionId,
                    QuestionTypeId = row.QuestionTypeId,
                    QuestionText = row.QuestionText,
                    Points = row.Points,
                    SortOrder = row.SortOrder,
                    Difficulty = row.Difficulty,
                    ExplanationVisibility = row.ExplanationVisibility,
                    RandomizeAnswerOptions = row.RandomizeAnswerOptions,
                    ScoringPolicy = row.ScoringPolicy,
                    ReviewStatus = row.ReviewStatus,
                    IsGeneratedByAi = row.IsGeneratedByAi,
                    CreatedByUserId = row.CreatedByUserId,
                    CreatedAt = row.CreatedAt,
                    UpdatedAt = row.UpdatedAt,
                    DeletedAt = row.DeletedAt,
                    QuestionType = new QuestionType
                    {
                        QuestionTypeId = row.QuestionTypeId,
                        Code = row.QuestionTypeCode,
                        SupportsMultipleCorrectAnswers = row.QuestionTypeSupportsMultiple,
                    },
                    AnswerOptions = optionsByQuestion.GetValueOrDefault(row.QuestionId) ?? [],
                    CorrectAnswerOptions = correctByQuestion.GetValueOrDefault(row.QuestionId) ?? [],
                    Justification = justification,
                };
            })
            .ToList();
    }

    private sealed class QuestionRow
    {
        public Guid QuestionId { get; init; }
        public Guid QuizId { get; init; }
        public Guid? QuizSectionId { get; init; }
        public int QuestionTypeId { get; init; }
        public string QuestionText { get; init; } = string.Empty;
        public decimal Points { get; init; }
        public int SortOrder { get; init; }
        public string? Difficulty { get; init; }
        public string ExplanationVisibility { get; init; } = "never";
        public bool RandomizeAnswerOptions { get; init; }
        public string ScoringPolicy { get; init; } = "strict";
        public string ReviewStatus { get; init; } = "approved";
        public bool IsGeneratedByAi { get; init; }
        public Guid CreatedByUserId { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime? UpdatedAt { get; init; }
        public DateTime? DeletedAt { get; init; }
        public string QuestionTypeCode { get; init; } = string.Empty;
        public bool QuestionTypeSupportsMultiple { get; init; }
    }
}
