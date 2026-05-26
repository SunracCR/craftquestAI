using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Services.Imports;

/// <summary>
/// Applies quiz-level CQIF defaults (e.g. default_points) to each question before preview/confirm.
/// </summary>
public static class CqifDocumentNormalizer
{
    public static void ApplyQuizDefaults(CqifDocument document, decimal quizDefaultQuestionPoints = 1m)
    {
        var fallbackPoints = document.Quiz.DefaultPoints ?? quizDefaultQuestionPoints;
        if (fallbackPoints <= 0)
        {
            fallbackPoints = 1m;
        }

        foreach (var question in document.Questions)
        {
            if (question.Points is null or <= 0)
            {
                question.Points = fallbackPoints;
            }
        }
    }
}
