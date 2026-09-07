using CraftQuest.Infrastructure.Services.Ai;

namespace CraftQuest.UnitTests.Ai;

public class AiGenerationAutoImportRulesTests
{
    [Theory]
    [InlineData(0, true)]
    [InlineData(-1, true)]
    [InlineData(1, false)]
    [InlineData(100, false)]
    public void ShouldFailBeforeConfirm_WhenNoValidQuestions(int validQuestions, bool shouldFail)
    {
        Assert.Equal(shouldFail, AiGenerationAutoImportRules.ShouldFailBeforeConfirm(validQuestions));
    }

    [Theory]
    [InlineData(0, true)]
    [InlineData(-1, true)]
    [InlineData(1, false)]
    [InlineData(100, false)]
    public void ShouldFailAfterConfirm_WhenNothingImported(int createdQuestions, bool shouldFail)
    {
        Assert.Equal(shouldFail, AiGenerationAutoImportRules.ShouldFailAfterConfirm(createdQuestions));
    }
}
