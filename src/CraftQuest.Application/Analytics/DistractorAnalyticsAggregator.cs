using CraftQuest.Application.Models.Analytics;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Analytics;

/// <summary>
/// Builds per-question distractor selection rates from finished practice session snapshots (RF-ANA-001).
/// </summary>
public static class DistractorAnalyticsAggregator
{
    public static IReadOnlyList<QuestionAnalyticsDto> BuildFromSessions(
        IReadOnlyList<Question> questions,
        IReadOnlyList<PracticeSession> sessions)
    {
        var questionStats = new Dictionary<Guid, (int Attempts, int Correct, int Incorrect, int Omitted)>();
        var optionSelected = new Dictionary<Guid, int>();

        foreach (var session in sessions)
        {
            foreach (var snapshot in session.QuestionSnapshots)
            {
                if (!questionStats.TryGetValue(snapshot.QuestionId, out var stats))
                {
                    stats = (0, 0, 0, 0);
                }

                stats.Attempts++;
                switch (snapshot.AnswerStatus)
                {
                    case "answered" when snapshot.IsCorrect == true:
                        stats.Correct++;
                        break;
                    case "answered":
                        stats.Incorrect++;
                        break;
                    default:
                        stats.Omitted++;
                        break;
                }

                questionStats[snapshot.QuestionId] = stats;

                foreach (var answer in snapshot.AnswerOptionSnapshots.Where(a => a.WasSelected))
                {
                    optionSelected[answer.AnswerOptionId] =
                        optionSelected.GetValueOrDefault(answer.AnswerOptionId) + 1;
                }
            }
        }

        return questions
            .Select(q =>
            {
                questionStats.TryGetValue(q.QuestionId, out var stats);
                var attempts = stats.Attempts;
                var correctIds = q.CorrectAnswerOptions
                    .Select(c => c.AnswerOptionId)
                    .ToHashSet();

                return new QuestionAnalyticsDto
                {
                    QuestionId = q.QuestionId,
                    QuestionText = q.QuestionText,
                    AttemptsCount = attempts,
                    CorrectCount = stats.Correct,
                    IncorrectCount = stats.Incorrect,
                    OmittedCount = stats.Omitted,
                    AnswerOptions = q.AnswerOptions
                        .OrderBy(o => o.DefaultSortOrder)
                        .Select(o =>
                        {
                            var selected = optionSelected.GetValueOrDefault(o.AnswerOptionId);
                            return new AnswerOptionAnalyticsDto
                            {
                                AnswerOptionId = o.AnswerOptionId,
                                StableKey = o.StableKey,
                                Text = o.AnswerText,
                                IsCorrect = correctIds.Contains(o.AnswerOptionId),
                                SelectedCount = selected,
                                SelectionRate = attempts > 0
                                    ? Math.Round((decimal)selected / attempts * 100, 2)
                                    : 0,
                            };
                        })
                        .ToList(),
                };
            })
            .ToList();
    }
}
