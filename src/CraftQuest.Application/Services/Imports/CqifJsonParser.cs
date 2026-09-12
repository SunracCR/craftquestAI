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

    private static readonly string[] CorrectAnswerKeyFieldAliases =
    [
        "correctAnswerKeys",
        "correctAnswerKey",
        "correctAnswer",
        "correctAnswers",
        "correct",
    ];

    private static void CoerceCorrectAnswerKeys(JsonObject question)
    {
        var options = question["answerOptions"] as JsonArray;
        var resolvedKeys = new List<string>();

        var aliasField = FindCorrectAnswerAliasField(question);
        if (aliasField is not null)
        {
            resolvedKeys.AddRange(ResolveCorrectAnswerValues(aliasField.Value.Node, options));
        }

        foreach (var key in ExtractCorrectKeysFromOptions(options))
        {
            if (!ContainsKey(resolvedKeys, key))
            {
                resolvedKeys.Add(key);
            }
        }

        if (resolvedKeys.Count == 0)
        {
            return;
        }

        question["correctAnswerKeys"] = new JsonArray(
            resolvedKeys.Select(k => JsonValue.Create(k)).ToArray());

        foreach (var alias in CorrectAnswerKeyFieldAliases)
        {
            if (!string.Equals(alias, "correctAnswerKeys", StringComparison.Ordinal)
                && question.ContainsKey(alias))
            {
                question.Remove(alias);
            }
        }
    }

    private static (string Name, JsonNode Node)? FindCorrectAnswerAliasField(JsonObject question)
    {
        foreach (var alias in CorrectAnswerKeyFieldAliases)
        {
            if (question[alias] is JsonNode node)
            {
                return (alias, node);
            }
        }

        return null;
    }

    private static IEnumerable<string> ResolveCorrectAnswerValues(JsonNode? node, JsonArray? options)
    {
        if (node is null)
        {
            yield break;
        }

        switch (node)
        {
            case JsonArray array:
                foreach (var item in array)
                {
                    foreach (var resolved in ResolveSingleCorrectAnswerValue(item, options))
                    {
                        yield return resolved;
                    }
                }

                break;
            default:
                foreach (var resolved in ResolveSingleCorrectAnswerValue(node, options))
                {
                    yield return resolved;
                }

                break;
        }
    }

    private static IEnumerable<string> ResolveSingleCorrectAnswerValue(JsonNode? node, JsonArray? options)
    {
        if (node is null)
        {
            yield break;
        }

        if (node is JsonValue value)
        {
            switch (value.GetValueKind())
            {
                case JsonValueKind.String:
                    var text = value.GetValue<string>()?.Trim();
                    if (string.IsNullOrWhiteSpace(text))
                    {
                        yield break;
                    }

                    foreach (var resolved in MapCorrectAnswerToken(text, options))
                    {
                        yield return resolved;
                    }

                    break;
                case JsonValueKind.Number:
                    if (options is not null
                        && value.TryGetValue<int>(out var index))
                    {
                        foreach (var resolved in MapCorrectAnswerIndex(index, options))
                        {
                            yield return resolved;
                        }
                    }

                    break;
            }

            yield break;
        }

        if (node is JsonObject obj && obj["key"] is JsonValue keyValue
            && keyValue.GetValueKind() == JsonValueKind.String)
        {
            var key = keyValue.GetValue<string>()?.Trim();
            if (!string.IsNullOrWhiteSpace(key))
            {
                yield return key;
            }
        }
    }

    private static IEnumerable<string> MapCorrectAnswerToken(string token, JsonArray? options)
    {
        if (options is null || options.Count == 0)
        {
            yield return token;
            yield break;
        }

        foreach (var option in options.OfType<JsonObject>())
        {
            var key = option["key"]?.GetValue<string>()?.Trim();
            var optionText = option["text"]?.GetValue<string>()?.Trim();

            if (!string.IsNullOrWhiteSpace(key)
                && string.Equals(key, token, StringComparison.OrdinalIgnoreCase))
            {
                yield return key;
                yield break;
            }

            if (!string.IsNullOrWhiteSpace(optionText)
                && string.Equals(optionText, token, StringComparison.OrdinalIgnoreCase))
            {
                yield return key ?? token;
                yield break;
            }
        }

        if (int.TryParse(token, out var numericIndex))
        {
            foreach (var resolved in MapCorrectAnswerIndex(numericIndex, options))
            {
                yield return resolved;
            }

            yield break;
        }

        yield return token;
    }

    private static IEnumerable<string> MapCorrectAnswerIndex(int index, JsonArray options)
    {
        var zeroBased = index >= 0 && index < options.Count ? index : -1;
        var oneBased = index >= 1 && index <= options.Count ? index - 1 : -1;
        var resolvedIndex = zeroBased >= 0 ? zeroBased : oneBased;

        if (resolvedIndex < 0 || resolvedIndex >= options.Count)
        {
            yield break;
        }

        if (options[resolvedIndex] is JsonObject option)
        {
            var key = option["key"]?.GetValue<string>()?.Trim();
            if (!string.IsNullOrWhiteSpace(key))
            {
                yield return key;
            }
        }
    }

    private static IEnumerable<string> ExtractCorrectKeysFromOptions(JsonArray? options)
    {
        if (options is null)
        {
            yield break;
        }

        foreach (var option in options.OfType<JsonObject>())
        {
            if (!IsMarkedCorrect(option))
            {
                continue;
            }

            var key = option["key"]?.GetValue<string>()?.Trim();
            if (!string.IsNullOrWhiteSpace(key))
            {
                yield return key;
            }
        }
    }

    private static bool IsMarkedCorrect(JsonObject option)
    {
        if (option["isCorrect"] is JsonValue isCorrect
            && isCorrect.GetValueKind() == JsonValueKind.True)
        {
            return true;
        }

        if (option["correct"] is JsonValue correct
            && correct.GetValueKind() == JsonValueKind.True)
        {
            return true;
        }

        return false;
    }

    private static bool ContainsKey(IReadOnlyList<string> keys, string candidate) =>
        keys.Any(k => string.Equals(k, candidate, StringComparison.OrdinalIgnoreCase));

    private static string NormalizePropertyNames(string json) =>
        json.Replace("\"Questions\"", "\"questions\"", StringComparison.Ordinal);

    [GeneratedRegex(@"```(?:json)?\s*(?<json>[\s\S]*?)```", RegexOptions.IgnoreCase)]
    private static partial Regex MarkdownJsonFenceRegex();
}
