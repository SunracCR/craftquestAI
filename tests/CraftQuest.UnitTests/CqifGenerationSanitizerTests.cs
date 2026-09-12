using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.StudyMaterials;

namespace CraftQuest.UnitTests;

public class CqifGenerationSanitizerTests
{
    [Fact]
    public void ValidateOrThrow_KeepsValidQuestionsAndDropsInvalidOnes()
    {
        var document = new CqifDocument
        {
            Questions =
            [
                CreateValidQuestion("Valid 1"),
                CreateValidQuestion("Valid 2"),
                CreateInvalidQuestion("Missing correct keys"),
            ],
        };

        CqifGenerationSanitizer.ValidateOrThrow(document);

        Assert.Equal(2, document.Questions.Count);
        Assert.All(document.Questions, q => Assert.NotEmpty(q.CorrectAnswerKeys));
    }

    [Fact]
    public void ValidateOrThrow_ThrowsAppExceptionWhenAllInvalid()
    {
        var document = new CqifDocument
        {
            Questions =
            [
                CreateInvalidQuestion("Invalid 1"),
                CreateInvalidQuestion("Invalid 2"),
            ],
        };

        var ex = Assert.Throws<AppException>(() => CqifGenerationSanitizer.ValidateOrThrow(document));

        Assert.Equal("AI_GENERATION_INVALID_OUTPUT", ex.ErrorCode);
        Assert.Empty(document.Questions);
    }

    private static CqifQuestion CreateValidQuestion(string text) =>
        new()
        {
            Type = "single_choice",
            Text = text,
            AnswerOptions =
            [
                new() { Key = "a", Text = "One" },
                new() { Key = "b", Text = "Two" },
            ],
            CorrectAnswerKeys = ["a"],
        };

    private static CqifQuestion CreateInvalidQuestion(string text) =>
        new()
        {
            Type = "single_choice",
            Text = text,
            AnswerOptions =
            [
                new() { Key = "a", Text = "One" },
                new() { Key = "b", Text = "Two" },
            ],
            CorrectAnswerKeys = [],
        };
}
