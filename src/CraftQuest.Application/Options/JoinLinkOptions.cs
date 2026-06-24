namespace CraftQuest.Application.Options;

public class JoinLinkOptions
{
    public const string SectionName = "JoinLinks";

    /// <summary>Public base URL for join links, e.g. https://api.craftquestai.com</summary>
    public string LinkBaseUrl { get; set; } = "https://localhost:7080";

    /// <summary>Flutter web app URL, e.g. https://app.craftquestai.com</summary>
    public string WebAppUrl { get; set; } = "http://localhost:8080";

    public string PlayStoreUrl { get; set; } =
        "https://play.google.com/store/apps/details?id=com.craftquestai.craftquestai_app";

    public string AppStoreUrl { get; set; } = "https://apps.apple.com/app/idPENDIENTE";

    public string AndroidPackageName { get; set; } = "com.craftquestai.craftquestai_app";

    public List<string> AndroidSha256Fingerprints { get; set; } = [];

    /// <summary>Apple app IDs in TEAMID.bundleId format for Universal Links.</summary>
    public List<string> IosAppIds { get; set; } = [];
}
