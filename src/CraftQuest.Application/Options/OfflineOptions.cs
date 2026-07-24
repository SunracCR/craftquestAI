namespace CraftQuest.Application.Options;

public class OfflineOptions
{
    public const string SectionName = "Offline";

    /// <summary>Master secret for deriving per-user/quiz offline package keys (min 32 chars in production).</summary>
    public string EncryptionSecret { get; set; } = "CraftQuest-Offline-Encryption-Secret-Change-In-Prod!";

    public int PackageTtlDays { get; set; } = 30;
}
