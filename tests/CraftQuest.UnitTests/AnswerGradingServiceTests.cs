using CraftQuest.Application.Services;

namespace CraftQuest.UnitTests;

public class AnswerGradingServiceTests
{
    /// <summary>TST-RND-002: grading uses option ids, not display labels A/B/C.</summary>
    [Fact]
    public void SingleChoice_TST_RND_002_CorrectByAnswerOptionId_NotDisplayLabel()
    {
        var optionShownAsA = Guid.NewGuid();
        var optionShownAsB = Guid.NewGuid();
        var selected = new HashSet<Guid> { optionShownAsA };
        var correct = new HashSet<Guid> { optionShownAsA };

        Assert.True(AnswerGradingService.IsAnswerCorrect(selected, correct, supportsMultipleCorrectAnswers: false));

        var wrongSelection = new HashSet<Guid> { optionShownAsB };
        Assert.False(AnswerGradingService.IsAnswerCorrect(
            wrongSelection,
            correct,
            supportsMultipleCorrectAnswers: false));
    }

    [Fact]
    public void SingleChoice_CorrectWhenSameId_EvenIfLabelWouldDiffer()
    {
        var correctId = Guid.NewGuid();
        var selected = new HashSet<Guid> { correctId };
        var correct = new HashSet<Guid> { correctId };

        Assert.True(AnswerGradingService.IsAnswerCorrect(selected, correct, supportsMultipleCorrectAnswers: false));
    }

    [Fact]
    public void SingleChoice_IncorrectWhenMultipleSelected()
    {
        var correctId = Guid.NewGuid();
        var otherId = Guid.NewGuid();
        var selected = new HashSet<Guid> { correctId, otherId };
        var correct = new HashSet<Guid> { correctId };

        Assert.False(AnswerGradingService.IsAnswerCorrect(selected, correct, supportsMultipleCorrectAnswers: false));
    }

    [Fact]
    public void MultipleChoice_RequiresExactSet()
    {
        var a = Guid.NewGuid();
        var b = Guid.NewGuid();
        var c = Guid.NewGuid();

        var selected = new HashSet<Guid> { a, b };
        var correct = new HashSet<Guid> { a, b };

        Assert.True(AnswerGradingService.IsAnswerCorrect(selected, correct, supportsMultipleCorrectAnswers: true));

        var partial = new HashSet<Guid> { a };
        Assert.False(AnswerGradingService.IsAnswerCorrect(partial, correct, supportsMultipleCorrectAnswers: true));
    }

    [Fact]
    public void DisplayLabels_AreSequentialLetters()
    {
        var labels = AnswerGradingService.BuildDisplayLabels(4);
        Assert.Equal(["A", "B", "C", "D"], labels);
    }

    [Fact]
    public void PartialMultiple_AwardsFractionPerCorrectSelection()
    {
        var a = Guid.NewGuid();
        var b = Guid.NewGuid();
        var c = Guid.NewGuid();
        var d = Guid.NewGuid();

        var selected = new HashSet<Guid> { a, b };
        var correct = new HashSet<Guid> { a, b, c };

        var result = AnswerGradingService.GradeAnswer(
            selected,
            correct,
            supportsMultipleCorrectAnswers: true,
            AnswerGradingService.PartialScoringPolicy,
            pointsPossible: 1);

        Assert.False(result.IsFullyCorrect);
        Assert.Equal(0.67m, result.PointsAwarded);
    }

    [Fact]
    public void PartialMultiple_SubtractsForWrongSelections()
    {
        var a = Guid.NewGuid();
        var b = Guid.NewGuid();
        var c = Guid.NewGuid();
        var d = Guid.NewGuid();

        var selected = new HashSet<Guid> { a, b, d };
        var correct = new HashSet<Guid> { a, b, c };

        var result = AnswerGradingService.GradeAnswer(
            selected,
            correct,
            supportsMultipleCorrectAnswers: true,
            AnswerGradingService.PartialScoringPolicy,
            pointsPossible: 1);

        Assert.False(result.IsFullyCorrect);
        Assert.Equal(0.33m, result.PointsAwarded);
    }

    [Fact]
    public void PartialMultiple_FullCreditWhenExactSet()
    {
        var a = Guid.NewGuid();
        var b = Guid.NewGuid();
        var c = Guid.NewGuid();

        var selected = new HashSet<Guid> { a, b, c };
        var correct = new HashSet<Guid> { a, b, c };

        var result = AnswerGradingService.GradeAnswer(
            selected,
            correct,
            supportsMultipleCorrectAnswers: true,
            AnswerGradingService.PartialScoringPolicy,
            pointsPossible: 1);

        Assert.True(result.IsFullyCorrect);
        Assert.Equal(1m, result.PointsAwarded);
    }

    [Fact]
    public void ResolveScoringPolicy_MultipleChoiceUsesPartial()
    {
        Assert.Equal(
            AnswerGradingService.PartialScoringPolicy,
            AnswerGradingService.ResolveScoringPolicyForQuestionType("multiple_choice", "strict"));
    }
}
