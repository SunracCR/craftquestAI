namespace CraftQuest.Application.Options;

public class PracticeOptions
{
    public const string SectionName = "Practice";

    /// <summary>Logs per-phase timing for practice session start (quiz load, bulk insert, etc.).</summary>
    public bool LogStartSessionTiming { get; set; } = true;

    /// <summary>
    /// When enabled, persists session + question snapshots + first-question options synchronously
    /// and inserts remaining answer-option snapshots in the background.
    /// </summary>
    public bool EnableDeferredSnapshotInsert { get; set; } = true;

    /// <summary>Minimum question count before deferred snapshot insert is applied.</summary>
    public int DeferredInsertMinQuestions { get; set; } = 50;

    /// <summary>Periodic lightweight reads to keep quiz/practice table pages in the SQL buffer pool.</summary>
    public bool EnableDatabaseKeepWarm { get; set; } = true;

    /// <summary>Interval between keep-warm database reads.</summary>
    public int KeepWarmIntervalMinutes { get; set; } = 2;

    /// <summary>Retries when loading a question whose options are still being persisted in the background.</summary>
    public int GetSessionQuestionRetryAttempts { get; set; } = 5;

    /// <summary>Base delay between retries for deferred option persistence (multiplied by attempt index).</summary>
    public int GetSessionQuestionRetryDelayMs { get; set; } = 100;
}
