using System.Text.Json.Serialization;

namespace CraftQuest.Application.Models.Imports;

public sealed class CqifDocument
{
    [JsonPropertyName("cqifVersion")]
    public string CqifVersion { get; set; } = "2.0";

    [JsonPropertyName("quiz")]
    public CqifQuizMetadata Quiz { get; set; } = new();

    [JsonPropertyName("questions")]
    public List<CqifQuestion> Questions { get; set; } = [];
}

public sealed class CqifQuizMetadata
{
    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("defaultPoints")]
    public decimal? DefaultPoints { get; set; }

    [JsonPropertyName("defaultRandomizeAnswerOptions")]
    public bool? DefaultRandomizeAnswerOptions { get; set; }
}

public sealed class CqifQuestion
{
    [JsonPropertyName("externalId")]
    public string? ExternalId { get; set; }

    [JsonPropertyName("section")]
    public string? Section { get; set; }

    [JsonPropertyName("order")]
    public int? Order { get; set; }

    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("text")]
    public string Text { get; set; } = string.Empty;

    [JsonPropertyName("points")]
    public decimal? Points { get; set; }

    [JsonPropertyName("difficulty")]
    public string? Difficulty { get; set; }

    [JsonPropertyName("randomizeAnswerOptions")]
    public bool? RandomizeAnswerOptions { get; set; }

    [JsonPropertyName("scoringPolicy")]
    public string? ScoringPolicy { get; set; }

    [JsonPropertyName("answerOptions")]
    public List<CqifAnswerOption> AnswerOptions { get; set; } = [];

    [JsonPropertyName("correctAnswerKeys")]
    public List<string> CorrectAnswerKeys { get; set; } = [];

    [JsonPropertyName("justification")]
    public CqifJustification? Justification { get; set; }
}

public sealed class CqifAnswerOption
{
    [JsonPropertyName("key")]
    public string Key { get; set; } = string.Empty;

    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("defaultOrder")]
    public int? DefaultOrder { get; set; }

    [JsonPropertyName("mediaFileName")]
    public string? MediaFileName { get; set; }
}

public sealed class CqifJustification
{
    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("status")]
    public string? Status { get; set; }

    [JsonPropertyName("visibility")]
    public string? Visibility { get; set; }

    [JsonPropertyName("sources")]
    public List<CqifJustificationSource> Sources { get; set; } = [];
}

public sealed class CqifJustificationSource
{
    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("url")]
    public string? Url { get; set; }

    [JsonPropertyName("provider")]
    public string? Provider { get; set; }

    [JsonPropertyName("snippet")]
    public string? Snippet { get; set; }

    [JsonPropertyName("pageNumber")]
    public int? PageNumber { get; set; }

    [JsonPropertyName("studyMaterialId")]
    public Guid? StudyMaterialId { get; set; }

    [JsonPropertyName("isPrimary")]
    public bool? IsPrimary { get; set; }
}
