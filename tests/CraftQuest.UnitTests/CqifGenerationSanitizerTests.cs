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

    [Theory]
    [InlineData("parís", "París")]
    [InlineData("¿cuál es la capital?", "¿Cuál es la capital?")]
    [InlineData("pH neutro", "pH neutro")]
    [InlineData("Paris", "Paris")]
    public void CapitalizeFirstLetter_CapitalizesFirstRealLetter(string input, string expected)
    {
        Assert.Equal(expected, CqifGenerationSanitizer.CapitalizeFirstLetter(input));
    }

    [Fact]
    public void SanitizeJustificationText_RemovesOptionLetterReferences()
    {
        const string input = "La opción B es correcta porque París es la capital de Francia.";
        const string expected = "París es la capital de Francia.";

        var result = CqifGenerationSanitizer.SanitizeJustificationText(input);

        Assert.Equal(expected, result);
    }

    [Fact]
    public void SanitizeJustificationText_PreservesConceptReferencesLikeVitaminA()
    {
        const string text = "La vitamina A es esencial para la visión nocturna.";

        var result = CqifGenerationSanitizer.SanitizeJustificationText(text);

        Assert.Equal(text, result);
    }

    [Fact]
    public void NormalizeQuestion_CapitalizesOptionsAndCleansJustification()
    {
        var question = new CqifQuestion
        {
            Type = "single_choice",
            Text = "¿Capital de Francia?",
            AnswerOptions =
            [
                new() { Key = "A", Text = "londres" },
                new() { Key = "B", Text = "parís" },
            ],
            CorrectAnswerKeys = ["B"],
            Justification = new CqifJustification
            {
                Text = "La opción B es correcta porque París es la capital.",
            },
        };

        var normalized = CqifGenerationSanitizer.NormalizeQuestion(question);

        Assert.Equal("Londres", normalized.AnswerOptions[0].Text);
        Assert.Equal("París", normalized.AnswerOptions[1].Text);
        Assert.Equal("París es la capital.", normalized.Justification!.Text);
    }

    [Fact]
    public void Sanitize_AppliesNormalizationToFilteredQuestions()
    {
        var document = new CqifDocument
        {
            Questions =
            [
                new CqifQuestion
                {
                    Type = "single_choice",
                    Text = "Test?",
                    AnswerOptions =
                    [
                        new() { Key = "A", Text = "berlín" },
                        new() { Key = "B", Text = "madrid" },
                    ],
                    CorrectAnswerKeys = ["A"],
                },
            ],
        };

        CqifGenerationSanitizer.Sanitize(document, ["single_choice"]);

        Assert.Equal("Berlín", document.Questions[0].AnswerOptions[0].Text);
        Assert.Equal("Madrid", document.Questions[0].AnswerOptions[1].Text);
    }
}
