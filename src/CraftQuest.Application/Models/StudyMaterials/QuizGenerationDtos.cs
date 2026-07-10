namespace CraftQuest.Application.Models.StudyMaterials;

public sealed class QuizGenerationParametersDto
{
    public Guid? TargetQuizId { get; set; }
    public int QuestionCount { get; set; } = 15;
    public string Language { get; set; } = "es";
    public string Difficulty { get; set; } = "mixed";
    public List<string> AllowedQuestionTypes { get; set; } =
        ["single_choice", "multiple_choice", "true_false"];
    public string? TopicFocus { get; set; }
    public string PedagogicalGoal { get; set; } = "assessment";
    public bool StrictSourceOnly { get; set; } = true;
    public bool IncludeExplanations { get; set; }
    public string? Preset { get; set; }
    /// <summary>Ignored by the server; generation always uses the full document.</summary>
    public int PageFrom { get; set; }
    /// <summary>Ignored by the server; generation always uses the full document.</summary>
    public int PageTo { get; set; }
}

public sealed class QuizGenerationEstimateDto
{
    public required int CreditsRequired { get; init; }
    public required int AiCreditsAvailable { get; init; }
    /// <summary>Preguntas que se generarán/importarán con la solicitud actual.</summary>
    public required int EstimatedImportableQuestions { get; init; }
    /// <summary>Máximo seleccionable (material + plan), independiente del count pedido.</summary>
    public required int MaxSelectableQuestions { get; init; }
    public required int WordsInScope { get; init; }
    /// <summary>Resolved from study material text (not UI locale).</summary>
    public required string GenerationLanguage { get; init; }
    /// <summary>Extra credits charged for medium/large documents (0, 1, or 2).</summary>
    public int DocumentSizeSurcharge { get; init; }
}

public sealed class StartQuizGenerationResultDto
{
    public required Guid AiJobId { get; init; }
    public required string Status { get; init; }
    public Guid? TargetQuizId { get; init; }
    public required int CreditsRequired { get; init; }
    /// <summary>True when an in-flight job already existed for this material (idempotent resume).</summary>
    public bool ResumedExistingJob { get; init; }
}
