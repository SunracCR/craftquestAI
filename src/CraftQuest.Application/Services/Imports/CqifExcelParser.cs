using ClosedXML.Excel;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Services.Imports;

public static class CqifExcelParser
{
    private static readonly Dictionary<string, string> TypeAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["single_choice"] = "single_choice",
        ["opcion unica"] = "single_choice",
        ["opción única"] = "single_choice",
        ["unica"] = "single_choice",
        ["única"] = "single_choice",
        ["single"] = "single_choice",
        ["multiple_choice"] = "multiple_choice",
        ["opcion multiple"] = "multiple_choice",
        ["opción múltiple"] = "multiple_choice",
        ["multiple"] = "multiple_choice",
        ["true_false"] = "true_false",
        ["verdadero falso"] = "true_false",
        ["verdadero/falso"] = "true_false",
        ["v/f"] = "true_false",
    };

    private static readonly string[] OptionColumnPrefixes =
    [
        "opcion ",
        "option ",
        "opção ",
        "opcao ",
        "answer ",
        "respuesta ",
        "resposta ",
    ];

    public static CqifDocument Parse(Stream stream)
    {
        if (stream is not { CanRead: true })
        {
            throw new AppException("Excel stream is not readable.", 400);
        }

        using var workbook = new XLWorkbook(stream);
        var worksheet = workbook.Worksheets.FirstOrDefault(w => w.RowsUsed().Any())
            ?? throw new AppException("Excel file has no worksheets with data.", 400);

        var headerRow = worksheet.FirstRowUsed();
        if (headerRow is null)
        {
            throw new AppException("Excel file is empty.", 400);
        }

        var columnMap = BuildColumnMap(headerRow);
        if (!columnMap.ContainsKey("question"))
        {
            throw new AppException(
                "Excel must include a 'Pregunta' (or 'Question') column in the first row.",
                400);
        }

        var questions = new List<CqifQuestion>();
        var order = 0;
        var lastRow = worksheet.LastRowUsed()?.RowNumber() ?? headerRow.RowNumber();

        for (var rowIndex = headerRow.RowNumber() + 1; rowIndex <= lastRow; rowIndex++)
        {
            var row = worksheet.Row(rowIndex);
            if (row.IsEmpty())
            {
                continue;
            }

            var questionText = GetCell(row, columnMap, "question");
            if (string.IsNullOrWhiteSpace(questionText))
            {
                continue;
            }

            order++;
            questions.Add(MapRow(row, columnMap, order, questionText));
        }

        if (questions.Count == 0)
        {
            throw new AppException("No questions found in the Excel file.", 400);
        }

        return new CqifDocument
        {
            CqifVersion = "2.0",
            Questions = questions,
        };
    }

    private static Dictionary<string, int> BuildColumnMap(IXLRow headerRow)
    {
        var map = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        var optionColumns = new List<(int Index, string Key)>();

        foreach (var cell in headerRow.CellsUsed())
        {
            var header = cell.GetString().Trim();
            if (header.Length == 0)
            {
                continue;
            }

            var normalized = NormalizeHeaderKey(header);
            var columnIndex = cell.Address.ColumnNumber;

            if (IsQuestionHeader(normalized))
            {
                map["question"] = columnIndex;
                continue;
            }

            if (IsTypeHeader(normalized))
            {
                map["type"] = columnIndex;
                continue;
            }

            if (IsCorrectHeader(normalized))
            {
                map["correct"] = columnIndex;
                continue;
            }

            if (IsPointsHeader(normalized))
            {
                map["points"] = columnIndex;
                continue;
            }

            if (IsSectionHeader(normalized))
            {
                map["section"] = columnIndex;
                continue;
            }

            if (IsDifficultyHeader(normalized))
            {
                map["difficulty"] = columnIndex;
                continue;
            }

            if (IsExternalIdHeader(normalized))
            {
                map["external_id"] = columnIndex;
                continue;
            }

            var optionKey = TryParseOptionColumn(normalized);
            if (optionKey is not null)
            {
                optionColumns.Add((columnIndex, optionKey));
            }
        }

        optionColumns = optionColumns
            .OrderBy(c => c.Key, StringComparer.OrdinalIgnoreCase)
            .ToList();

        for (var i = 0; i < optionColumns.Count; i++)
        {
            map[$"option:{optionColumns[i].Key}"] = optionColumns[i].Index;
        }

        return map;
    }

    private static CqifQuestion MapRow(
        IXLRow row,
        Dictionary<string, int> columnMap,
        int order,
        string questionText)
    {
        var rawType = GetCell(row, columnMap, "type");
        var type = NormalizeType(rawType);

        var answerOptions = columnMap
            .Where(kv => kv.Key.StartsWith("option:", StringComparison.Ordinal))
            .Select(kv =>
            {
                var key = kv.Key["option:".Length..];
                var text = row.Cell(kv.Value).GetString().Trim();
                return new CqifAnswerOption { Key = key.ToUpperInvariant(), Text = text };
            })
            .Where(o => !string.IsNullOrWhiteSpace(o.Text))
            .ToList();

        if (type == "true_false" && answerOptions.Count < 2)
        {
            answerOptions =
            [
                new CqifAnswerOption { Key = "A", Text = "Verdadero" },
                new CqifAnswerOption { Key = "B", Text = "Falso" },
            ];
        }

        var correctRaw = GetCell(row, columnMap, "correct");
        var correctKeys = ParseCorrectKeys(correctRaw);

        decimal? points = null;
        var pointsRaw = GetCell(row, columnMap, "points");
        if (!string.IsNullOrWhiteSpace(pointsRaw) &&
            decimal.TryParse(pointsRaw, out var parsedPoints))
        {
            points = parsedPoints;
        }

        return new CqifQuestion
        {
            ExternalId = GetCell(row, columnMap, "external_id"),
            Section = GetCell(row, columnMap, "section"),
            Order = order,
            Type = type,
            Text = questionText,
            Points = points,
            Difficulty = GetCell(row, columnMap, "difficulty"),
            ScoringPolicy = "strict",
            AnswerOptions = answerOptions,
            CorrectAnswerKeys = correctKeys,
        };
    }

    private static string NormalizeType(string? rawType)
    {
        if (string.IsNullOrWhiteSpace(rawType))
        {
            return "single_choice";
        }

        var trimmed = rawType.Trim();
        if (TypeAliases.TryGetValue(trimmed, out var mapped))
        {
            return mapped;
        }

        return trimmed.ToLowerInvariant().Replace(' ', '_');
    }

    private static List<string> ParseCorrectKeys(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return [];
        }

        return raw
            .Split(['|', ',', ';'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(k => k.ToUpperInvariant())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string? GetCell(IXLRow row, Dictionary<string, int> columnMap, string field) =>
        columnMap.TryGetValue(field, out var index)
            ? row.Cell(index).GetString().Trim()
            : null;

    private static string NormalizeHeaderKey(string header)
    {
        var normalized = header.Trim().ToLowerInvariant();
        return normalized
            .Replace('á', 'a')
            .Replace('à', 'a')
            .Replace('â', 'a')
            .Replace('ã', 'a')
            .Replace('é', 'e')
            .Replace('ê', 'e')
            .Replace('í', 'i')
            .Replace('ó', 'o')
            .Replace('ô', 'o')
            .Replace('õ', 'o')
            .Replace('ú', 'u')
            .Replace('ç', 'c');
    }

    private static bool IsQuestionHeader(string h) =>
        h is "pregunta" or "question" or "pergunta" or "text" or "texto";

    private static bool IsTypeHeader(string h) =>
        h is "tipo" or "type";

    private static bool IsCorrectHeader(string h) =>
        h is "respuesta correcta"
            or "resposta correta"
            or "correct"
            or "correcta"
            or "correct answer"
            or "correcto";

    private static bool IsPointsHeader(string h) =>
        h is "puntos" or "points" or "pontos";

    private static bool IsSectionHeader(string h) =>
        h is "seccion" or "section" or "secao";

    private static bool IsDifficultyHeader(string h) =>
        h is "dificultad" or "difficulty" or "dificuldade";

    private static bool IsExternalIdHeader(string h) =>
        h is "id" or "external_id" or "external id" or "codigo";

    private static string? TryParseOptionColumn(string header)
    {
        var normalized = NormalizeHeaderKey(header);
        foreach (var prefix in OptionColumnPrefixes)
        {
            if (!normalized.StartsWith(prefix, StringComparison.Ordinal))
            {
                continue;
            }

            var suffix = normalized[prefix.Length..].Trim();
            if (suffix.Length is >= 1 and <= 2)
            {
                return suffix.ToUpperInvariant();
            }
        }

        if (normalized is "opcion a" or "option a")
        {
            return "A";
        }

        return null;
    }
}
