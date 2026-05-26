using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Services.Imports;

public static partial class CqifJsonParser
{
    private static readonly JsonSerializerOptions Options = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
        NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString,
    };

    public static CqifDocument Parse(string rawText)
    {
        if (string.IsNullOrWhiteSpace(rawText))
        {
            throw new AppException("JSON content is empty.", 400, "AI_GENERATION_INVALID_OUTPUT");
        }

        var normalized = NormalizeRawJson(rawText);

        try
        {
            return DeserializeDocument(normalized);
        }
        catch (JsonException ex)
        {
            try
            {
                return DeserializeFromFlexibleRoot(normalized);
            }
            catch (Exception)
            {
                throw new AppException(
                    "The AI returned a response that could not be converted to a valid quiz format. Please try again.",
                    400,
                    "AI_GENERATION_INVALID_OUTPUT",
                    new Dictionary<string, object?> { ["detail"] = ex.Message });
            }
        }
    }

    private static CqifDocument DeserializeDocument(string json)
    {
        var document = JsonSerializer.Deserialize<CqifDocument>(json, Options)
            ?? throw new JsonException("Document is null.");

        if (document.Questions.Count == 0)
        {
            throw new JsonException("Document has no questions.");
        }

        return document;
    }

    private static CqifDocument DeserializeFromFlexibleRoot(string json)
    {
        var node = JsonNode.Parse(json) ?? throw new JsonException("Root is null.");

        return node switch
        {
            JsonArray questionsArray => new CqifDocument
            {
                CqifVersion = "2.0",
                Questions = questionsArray.Deserialize<List<CqifQuestion>>(Options) ?? [],
            },
            JsonObject obj when obj["questions"] is JsonArray q => DeserializeDocument(obj.ToJsonString()),
            JsonObject obj when obj["Questions"] is JsonArray => DeserializeDocument(
                NormalizePropertyNames(obj.ToJsonString())),
            _ => throw new JsonException("Unsupported JSON root."),
        };
    }

    public static string NormalizeRawJson(string rawText)
    {
        var text = rawText.Trim();

        if (text.StartsWith('\uFEFF'))
        {
            text = text[1..].Trim();
        }

        var fenced = MarkdownJsonFenceRegex().Match(text);
        if (fenced.Success)
        {
            text = fenced.Groups["json"].Value.Trim();
        }

        var firstObject = text.IndexOf('{');
        var firstArray = text.IndexOf('[');

        if (firstObject >= 0 && (firstArray < 0 || firstObject < firstArray))
        {
            var lastObject = text.LastIndexOf('}');
            if (lastObject > firstObject)
            {
                text = text[firstObject..(lastObject + 1)];
            }
        }
        else if (firstArray >= 0)
        {
            var lastArray = text.LastIndexOf(']');
            if (lastArray > firstArray)
            {
                text = text[firstArray..(lastArray + 1)];
            }
        }

        return CoerceCommonAiJsonIssues(text);
    }

    private static string CoerceCommonAiJsonIssues(string json)
    {
        try
        {
            var node = JsonNode.Parse(json);
            if (node is not JsonObject root)
            {
                return json;
            }

            if (root["questions"] is JsonArray questions)
            {
                foreach (var question in questions.OfType<JsonObject>())
                {
                    CoerceCorrectAnswerKeys(question);
                }
            }

            return root.ToJsonString();
        }
        catch
        {
            return json;
        }
    }

    private static void CoerceCorrectAnswerKeys(JsonObject question)
    {
        var keysNode = question["correctAnswerKeys"];
        if (keysNode is JsonValue value && value.GetValueKind() == JsonValueKind.String)
        {
            question["correctAnswerKeys"] = new JsonArray(value.GetValue<string>());
        }
    }

    private static string NormalizePropertyNames(string json) =>
        json.Replace("\"Questions\"", "\"questions\"", StringComparison.Ordinal);

    [GeneratedRegex(@"```(?:json)?\s*(?<json>[\s\S]*?)```", RegexOptions.IgnoreCase)]
    private static partial Regex MarkdownJsonFenceRegex();
}
