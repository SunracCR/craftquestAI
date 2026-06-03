using System.Text.Json;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Services.Quizzes;

public static class QuestionJustificationMapper
{
    private static readonly JsonSerializerOptions SnapshotJsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public static QuestionJustificationInput? FromCqif(CqifJustification? cqif) =>
        cqif is null || string.IsNullOrWhiteSpace(cqif.Text)
            ? null
            : new QuestionJustificationInput
            {
                Text = cqif.Text.Trim(),
                Visibility = "never",
                Sources = cqif.Sources
                    .Select(s => new QuestionJustificationSourceInput
                    {
                        Title = s.Title,
                        SourceUrl = s.Url,
                        Provider = s.Provider,
                        Snippet = s.Snippet,
                        PageNumber = s.PageNumber,
                        StudyMaterialId = s.StudyMaterialId,
                        IsPrimary = s.IsPrimary ?? false,
                    })
                    .ToList(),
            };

    public static QuestionJustificationDto? MapDto(Question question)
    {
        var j = question.Justification;
        if (j is null || string.IsNullOrWhiteSpace(j.JustificationText))
        {
            return null;
        }

        return new QuestionJustificationDto
        {
            Text = j.JustificationText,
            Status = j.Status,
            GeneratedByAi = j.GeneratedByAi,
            Visibility = question.ExplanationVisibility,
            Sources = j.Sources
                .OrderByDescending(s => s.IsPrimary)
                .ThenBy(s => s.SourcePageNumber)
                .Select(s => new QuestionJustificationSourceDto
                {
                    JustificationSourceId = s.JustificationSourceId,
                    Title = s.SourceTitle,
                    SourceUrl = s.SourceUrl,
                    Provider = s.SourceProvider,
                    Snippet = s.Snippet,
                    PageNumber = s.SourcePageNumber,
                    StudyMaterialId = s.StudyMaterialId,
                    IsPrimary = s.IsPrimary,
                })
                .ToList(),
        };
    }

    public static (string? Text, string? SourcesJson) BuildPracticeSnapshot(QuestionJustification? justification)
    {
        if (justification is null || string.IsNullOrWhiteSpace(justification.JustificationText))
        {
            return (null, null);
        }

        var sources = justification.Sources
            .OrderByDescending(s => s.IsPrimary)
            .ThenBy(s => s.SourcePageNumber)
            .Select(s => new QuestionJustificationSourceReviewDto
            {
                Title = s.SourceTitle,
                SourceUrl = s.SourceUrl,
                Snippet = s.Snippet,
                PageNumber = s.SourcePageNumber,
                IsPrimary = s.IsPrimary,
            })
            .ToList();

        var sourcesJson = sources.Count > 0
            ? JsonSerializer.Serialize(sources, SnapshotJsonOptions)
            : null;

        return (justification.JustificationText, sourcesJson);
    }

    public static IReadOnlyList<QuestionJustificationSourceReviewDto> ParseSnapshotSources(
        string? sourcesJson)
    {
        if (string.IsNullOrWhiteSpace(sourcesJson))
        {
            return [];
        }

        try
        {
            return JsonSerializer.Deserialize<List<QuestionJustificationSourceReviewDto>>(
                       sourcesJson,
                       SnapshotJsonOptions)
                   ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string ResolveSourceUrl(QuestionJustificationSourceInput source)
    {
        if (!string.IsNullOrWhiteSpace(source.SourceUrl))
        {
            return source.SourceUrl.Trim();
        }

        if (source.PageNumber is > 0)
        {
            return $"craftquest://source#page={source.PageNumber.Value}";
        }

        if (source.StudyMaterialId is Guid materialId)
        {
            return $"craftquest://study-material/{materialId:D}";
        }

        return string.Empty;
    }
}
