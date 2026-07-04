namespace CraftQuest.Application.Options;

public class JoinLinkOptions
{
    public const string SectionName = "JoinLinks";

    /// <summary>Public base URL for join links (API), e.g. https://api.craftquestai.com</summary>
    public string LinkBaseUrl { get; set; } = "https://api.craftquestai.com";

    /// <summary>Flutter web app URL, e.g. https://app.craftquestai.com</summary>
    public string WebAppUrl { get; set; } = "https://app.craftquestai.com";

    public string PlayStoreUrl { get; set; } =
        "https://play.google.com/store/apps/details?id=com.craftquestai.craftquestai_app";

    public string AppStoreUrl { get; set; } = "https://apps.apple.com/app/idPENDIENTE";

    public string AndroidPackageName { get; set; } = "com.craftquestai.craftquestai_app";

    public List<string> AndroidSha256Fingerprints { get; set; } = [];

    /// <summary>Apple app IDs in TEAMID.bundleId format for Universal Links.</summary>
    public List<string> IosAppIds { get; set; } = [];

    /// <summary>Absolute URL for Open Graph when a Prep+ item has no cover image.</summary>
    public string? DefaultOgImageUrl { get; set; }
}
