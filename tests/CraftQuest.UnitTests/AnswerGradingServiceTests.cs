using CraftQuest.Application.Services;

namespace CraftQuest.UnitTests;

public class AnswerGradingServiceTests
{
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
}
