using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.Quizzes;

namespace CraftQuest.Application.Services.Imports;

public static class CqifImportMapper
{
    public static CreateQuestionRequest ToCreateQuestionRequest(
        CqifQuestion question,
        decimal defaultPoints)
    {
        var options = question.AnswerOptions
            .Select((option, index) => new CreateAnswerOptionRequest
            {
                ClientKey = option.Key,
                Text = option.Text,
                DefaultSortOrder = option.DefaultOrder ?? (index + 1),
            })
            .ToList();

        if (string.Equals(question.Type, "image_based_question", StringComparison.OrdinalIgnoreCase)
            && !options.Any(o =>
                string.Equals(o.ClientKey, "QUESTION_IMAGE", StringComparison.OrdinalIgnoreCase)))
        {
            options.Insert(
                0,
                new CreateAnswerOptionRequest
                {
                    ClientKey = "QUESTION_IMAGE",
                    Text = " ",
                    DefaultSortOrder = -1,
                });
        }

        return new CreateQuestionRequest
        {
            QuestionType = question.Type,
            Text = question.Text,
            Points = question.Points ?? defaultPoints,
            RandomizeAnswerOptions = question.RandomizeAnswerOptions ?? true,
            ScoringPolicy = question.ScoringPolicy ?? "strict",
            AnswerOptions = options,
            CorrectAnswerKeys = question.CorrectAnswerKeys.ToList(),
            Justification = question.Justification?.Text is { Length: > 0 } text
                ? new QuestionJustificationInput
                {
                    Text = text,
                    Visibility = question.Justification.Visibility ?? "after_quiz",
                }
                : null,
        };
    }
}
