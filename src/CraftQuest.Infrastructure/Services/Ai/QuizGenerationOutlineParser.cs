using System.Text.Json;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Services.Imports;

namespace CraftQuest.Infrastructure.Services.Ai;

internal static class QuizGenerationOutlineParser
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public static QuizGenerationOutlinePlan Parse(string rawJson, int expectedCount, int chunkCount)
    {
        var normalized = CqifJsonParser.NormalizeRawJson(rawJson);
        using var document = JsonDocument.Parse(normalized);
        var root = document.RootElement;

        var itemsElement = root.ValueKind switch
        {
            JsonValueKind.Array => root,
            JsonValueKind.Object when root.TryGetProperty("items", out var items) => items,
            JsonValueKind.Object when root.TryGetProperty("outline", out var outline) => outline,
            _ => throw new AppException("Outline response is not a JSON array.", 502, "AI_GENERATION_INVALID_OUTPUT"),
        };

        var parsed = new List<QuizGenerationOutlineItem>();
        foreach (var element in itemsElement.EnumerateArray())
        {
            if (element.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            var index = element.TryGetProperty("index", out var indexProp) && indexProp.TryGetInt32(out var idx)
                ? idx
                : parsed.Count + 1;
            var topic = element.TryGetProperty("topic", out var topicProp)
                ? topicProp.GetString()
                : element.TryGetProperty("focus", out var focusProp)
                    ? focusProp.GetString()
                    : null;
            if (string.IsNullOrWhiteSpace(topic))
            {
                continue;
            }

            var suggestedType = element.TryGetProperty("suggestedType", out var typeProp)
                ? typeProp.GetString()
                : element.TryGetProperty("type", out var altTypeProp)
                    ? altTypeProp.GetString()
                    : null;

            var chunkIndex = element.TryGetProperty("chunkIndex", out var chunkProp) && chunkProp.TryGetInt32(out var chunk)
                ? chunk
                : index;

            parsed.Add(new QuizGenerationOutlineItem(index, topic.Trim(), suggestedType?.Trim(), chunkIndex));
        }

        if (parsed.Count == 0)
        {
            throw new AppException("Outline response contained no items.", 502, "AI_GENERATION_INVALID_OUTPUT");
        }

        var boundedChunkCount = Math.Max(1, chunkCount);
        var trimmed = parsed
            .Take(expectedCount)
            .Select((item, i) => item with
            {
                Index = i + 1,
                ChunkIndex = Math.Clamp(item.ChunkIndex, 1, boundedChunkCount),
            })
            .ToList();

        while (trimmed.Count < expectedCount)
        {
            var nextIndex = trimmed.Count + 1;
            trimmed.Add(new QuizGenerationOutlineItem(
                nextIndex,
                $"Cover remaining material (question {nextIndex})",
                null,
                ((nextIndex - 1) % boundedChunkCount) + 1));
        }

        return new QuizGenerationOutlinePlan { Items = trimmed };
    }
}
