using CraftQuest.Application.Services.Imports;

namespace CraftQuest.UnitTests;

public class CqifImportTests
{
    [Fact]
    public void JsonParser_ParsesExampleDocument()
    {
        var path = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory,
            "..", "..", "..", "..", "..",
            "Documentacion",
            "CraftQuest_CQIF_Ejemplo_RespuestasPorID.json"));

        var json = File.ReadAllText(path);
        var document = CqifJsonParser.Parse(json);

        Assert.Equal("2.0", document.CqifVersion);
        Assert.Equal(2, document.Questions.Count);
        Assert.Contains(document.Questions, q => q.CorrectAnswerKeys.Contains("ALL"));
    }

    [Fact]
    public void TxtParser_ParsesExampleFormat()
    {
        var path = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory,
            "..", "..", "..", "..", "..",
            "Documentacion",
            "CraftQuest_Formato_TXT_Ejemplo_v4.txt"));

        var text = File.ReadAllText(path);
        var document = CqifTxtParser.Parse(text);

        Assert.True(document.Questions.Count >= 2);
        Assert.Contains(document.Questions, q => q.CorrectAnswerKeys.Contains("ALL"));
        Assert.Contains(document.Questions, q => q.Type == "multiple_choice");
    }

    [Fact]
    public void Validator_RejectsUnknownCorrectKey()
    {
        var question = new Application.Models.Imports.CqifQuestion
        {
            Type = "single_choice",
            Text = "Test?",
            AnswerOptions =
            [
                new() { Key = "A", Text = "One" },
                new() { Key = "B", Text = "Two" },
            ],
            CorrectAnswerKeys = ["Z"],
        };

        var issues = CqifValidator.ValidateQuestion(question, 1);

        Assert.Contains(issues, i => i.ErrorCode == "CORRECT_KEY_UNKNOWN");
    }

    [Fact]
    public void Validator_AllowsValidSingleChoice()
    {
        var question = new Application.Models.Imports.CqifQuestion
        {
            Type = "single_choice",
            Text = "Test?",
            AnswerOptions =
            [
                new() { Key = "A", Text = "One" },
                new() { Key = "B", Text = "Two" },
            ],
            CorrectAnswerKeys = ["A"],
        };

        var issues = CqifValidator.ValidateQuestion(question, 1)
            .Where(i => i.Severity == "error")
            .ToList();

        Assert.Empty(issues);
    }
}
