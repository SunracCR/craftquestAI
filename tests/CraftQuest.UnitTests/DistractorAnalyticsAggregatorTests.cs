using CraftQuest.Application.Analytics;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Domain.Entities;

namespace CraftQuest.UnitTests;

public class DistractorAnalyticsAggregatorTests
{
    [Fact]
    public void BuildFromSessions_CountsSelectionsPerAnswerOptionId()
    {
        var questionId = Guid.NewGuid();
        var correctOptionId = Guid.NewGuid();
        var distractorOptionId = Guid.NewGuid();

        var question = new Question
        {
            QuestionId = questionId,
            QuizId = Guid.NewGuid(),
            QuestionText = "Sample?",
            SortOrder = 1,
            AnswerOptions =
            [
                new QuestionAnswerOption
                {
                    AnswerOptionId = correctOptionId,
                    QuestionId = questionId,
                    StableKey = "A",
                    AnswerText = "Yes",
                    DefaultSortOrder = 1,
                    IsActive = true,
                },
                new QuestionAnswerOption
                {
                    AnswerOptionId = distractorOptionId,
                    QuestionId = questionId,
                    StableKey = "B",
                    AnswerText = "No",
                    DefaultSortOrder = 2,
                    IsActive = true,
                },
            ],
            CorrectAnswerOptions =
            [
                new QuestionCorrectAnswerOption
                {
                    QuestionId = questionId,
                    AnswerOptionId = correctOptionId,
                },
            ],
        };

        var snapshot = new PracticeQuestionSnapshot
        {
            QuestionId = questionId,
            AnswerStatus = "answered",
            IsCorrect = false,
            AnswerOptionSnapshots =
            [
                new PracticeAnswerOptionSnapshot
                {
                    AnswerOptionId = distractorOptionId,
                    WasSelected = true,
                },
            ],
        };

        var session = new PracticeSession
        {
            PracticeSessionId = Guid.NewGuid(),
            QuizId = question.QuizId,
            Status = "finished",
            QuestionSnapshots = [snapshot],
        };

        var result = DistractorAnalyticsAggregator.BuildFromSessions([question], [session]);
        var analytics = Assert.Single(result);
        Assert.Equal(1, analytics.AttemptsCount);

        var distractor = analytics.AnswerOptions.Single(o => o.AnswerOptionId == distractorOptionId);
        Assert.Equal(1, distractor.SelectedCount);
        Assert.Equal(100m, distractor.SelectionRate);

        var correct = analytics.AnswerOptions.Single(o => o.AnswerOptionId == correctOptionId);
        Assert.Equal(0, correct.SelectedCount);
        Assert.Equal(0m, correct.SelectionRate);
    }

}
