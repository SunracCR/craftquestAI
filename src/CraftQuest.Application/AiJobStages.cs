namespace CraftQuest.Application;

/// <summary>Stable stage codes for AI jobs (UI maps to localized labels).</summary>
public static class AiJobStages
{
    public const string Queued = "queued";
    public const string Preparing = "preparing";
    public const string Outlining = "outlining";
    public const string Generating = "generating";
    public const string Merging = "merging";
    public const string Validating = "validating";
    public const string Importing = "importing";
    public const string Completed = "completed";
    public const string Failed = "failed";
}
