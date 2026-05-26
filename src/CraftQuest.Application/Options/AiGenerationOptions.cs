namespace CraftQuest.Application.Options;

public class AiGenerationOptions
{
    public const string SectionName = "AiGeneration";

    public long MaxUploadBytes { get; set; } = 26_214_400;
    public int MaxPagesPerMaterial { get; set; } = 120;
    public int MaxPagesPerGeneration { get; set; } = 30;
    public int MaxWordsPerGeneration { get; set; } = 12_000;
    public int MaxQuestionsPerGeneration { get; set; } = 40;
    public int RetentionDays { get; set; } = 3;
    public string[] AllowedExtensions { get; set; } = [".pdf", ".docx"];
    public int ScannedPdfMinWordsPerPage { get; set; } = 8;
    public double ScannedPdfEmptyPageRatio { get; set; } = 0.6;
    public int GenerationJobMaxAttempts { get; set; } = 4;
    public int DeferredRetryMaxAttempts { get; set; } = 3;
    public int[] DeferredRetryDelayMinutes { get; set; } = [2, 5, 15];
    public int StaleProcessingMinutes { get; set; } = 12;
    public int GenerationJobTimeoutMinutes { get; set; } = 15;
    /// <summary>Shorter window when user starts a new generation (unblocks stuck jobs sooner).</summary>
    public int StaleProcessingMinutesOnStart { get; set; } = 8;
    public int ChunkTargetWordsPerRequest { get; set; } = 3800;
    public int MaxParallelChunkRequests { get; set; } = 3;
    public bool UseOutlinePhase { get; set; } = true;
    public int OutlineMaxSourceCharacters { get; set; } = 10_000;
    public int MinQuestionsForOutlinePhase { get; set; } = 5;
    public string OutlineGeminiModel { get; set; } = "gemini-2.5-flash-lite";
    public bool DeduplicateMergedQuestions { get; set; } = true;
    /// <summary>Temporary diagnostic logging for AI generation pipeline.</summary>
    public bool EnableAiGenerationTraceLogging { get; set; } = true;
    public string TraceLogDirectory { get; set; } = "logs/ai-gen-trace";
    public int TraceMaxLoggedCharacters { get; set; } = 12_000;
}
