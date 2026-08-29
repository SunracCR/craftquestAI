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
    public void ExcelTemplate_IncludesJustificationColumn()
    {
        var bytes = CqifExcelTemplateBuilder.Build("es");
        using var stream = new MemoryStream(bytes);
        var document = CqifExcelParser.Parse(stream);

        var withJustification = document.Questions
            .FirstOrDefault(q => q.Justification?.Text is { Length: > 0 });

        Assert.NotNull(withJustification);
        Assert.Contains("París", withJustification.Justification!.Text!, StringComparison.Ordinal);
    }

    [Fact]
    public void ExcelParser_AcceptsOptionalChapterColumn()
    {
        using var workbook = new ClosedXML.Excel.XLWorkbook();
        var sheet = workbook.AddWorksheet("Preguntas");
        sheet.Cell(1, 1).Value = "Pregunta";
        sheet.Cell(1, 2).Value = "Tipo";
        sheet.Cell(1, 3).Value = "Opción A";
        sheet.Cell(1, 4).Value = "Opción B";
        sheet.Cell(1, 5).Value = "Respuesta correcta";
        sheet.Cell(1, 6).Value = "Capítulo";
        sheet.Cell(2, 1).Value = "¿2+2?";
        sheet.Cell(2, 2).Value = "Opción múltiple";
        sheet.Cell(2, 3).Value = "3";
        sheet.Cell(2, 4).Value = "4";
        sheet.Cell(2, 5).Value = "B";
        sheet.Cell(2, 6).Value = "Álgebra";

        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        stream.Position = 0;

        var document = CqifExcelParser.Parse(stream);

        Assert.Single(document.Questions);
        Assert.Equal("Álgebra", document.Questions[0].Chapter);
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
