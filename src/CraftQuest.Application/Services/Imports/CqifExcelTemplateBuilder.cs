using ClosedXML.Excel;

namespace CraftQuest.Application.Services.Imports;

public static class CqifExcelTemplateBuilder
{
    /// <summary>Valores admitidos por <see cref="CqifValidator"/> para la columna Tipo.</summary>
    public static readonly string[] QuestionTypes =
    [
        "single_choice",
        "multiple_choice",
        "true_false",
        "image_choice",
        "image_based_question",
    ];

    private const int TypeColumnIndex = 2;
    private const int CorrectColumnIndex = 7;
    private const int PointsColumnIndex = 8;
    private const int SectionColumnIndex = 9;
    private const int JustificationColumnIndex = 10;
    private const int FirstDataRow = 2;
    private const int LastDataRow = 500;

    public static byte[] Build(string? languageCode = null)
    {
        var texts = CqifExcelTemplateTexts.Get(languageCode);

        using var workbook = new XLWorkbook();
        var sheet = workbook.AddWorksheet(texts.SheetName);
        var typesSheet = workbook.AddWorksheet("_TiposPregunta");
        typesSheet.Visibility = XLWorksheetVisibility.Hidden;

        for (var i = 0; i < QuestionTypes.Length; i++)
        {
            typesSheet.Cell(i + 1, 1).Value = QuestionTypes[i];
        }

        var typeListRange = typesSheet.Range(1, 1, QuestionTypes.Length, 1);

        for (var i = 0; i < texts.Headers.Length; i++)
        {
            var headerCell = sheet.Cell(1, i + 1);
            headerCell.Value = texts.Headers[i];
            headerCell.Style.Font.Bold = true;
            headerCell.Style.Fill.BackgroundColor = XLColor.FromHtml("#263238");
            headerCell.Style.Font.FontColor = XLColor.FromHtml("#FDFDFD");
        }

        var rowIndex = FirstDataRow;
        foreach (var example in texts.Examples)
        {
            sheet.Cell(rowIndex, 1).Value = example.Question;
            sheet.Cell(rowIndex, 2).Value = example.Type;
            for (var optionIndex = 0; optionIndex < 4; optionIndex++)
            {
                var optionText = example.Options[optionIndex];
                if (!string.IsNullOrWhiteSpace(optionText))
                {
                    sheet.Cell(rowIndex, 3 + optionIndex).Value = optionText;
                }
            }

            sheet.Cell(rowIndex, CorrectColumnIndex).Value = example.Correct;
            sheet.Cell(rowIndex, PointsColumnIndex).Value = example.Points;
            if (!string.IsNullOrWhiteSpace(example.Section))
            {
                sheet.Cell(rowIndex, SectionColumnIndex).Value = example.Section;
            }

            if (!string.IsNullOrWhiteSpace(example.Justification))
            {
                sheet.Cell(rowIndex, JustificationColumnIndex).Value = example.Justification;
            }

            rowIndex++;
        }

        var typeCells = sheet.Range(FirstDataRow, TypeColumnIndex, LastDataRow, TypeColumnIndex);
        var typeValidation = typeCells.CreateDataValidation();
        typeValidation.List(typeListRange);
        typeValidation.InCellDropdown = true;
        typeValidation.ShowErrorMessage = true;
        typeValidation.ErrorTitle = texts.TypeValidationErrorTitle;
        typeValidation.ErrorMessage = texts.TypeValidationErrorMessage;

        sheet.Columns().AdjustToContents();
        sheet.SheetView.FreezeRows(1);

        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }
}
