namespace CraftQuest.Application.Options;

public sealed class PushOptions
{
    public const string SectionName = "Push";

    public bool Enabled { get; set; }

    /// <summary>Path to Firebase service account JSON (server-side).</summary>
    public string? CredentialsPath { get; set; }
}
