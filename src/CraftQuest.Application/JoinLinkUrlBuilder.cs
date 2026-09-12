using CraftQuest.Application.Options;

namespace CraftQuest.Application;

public static class JoinLinkUrlBuilder
{
    private static readonly System.Text.RegularExpressions.Regex CodeFormat =
        new(@"^CQ-\d{6}$", System.Text.RegularExpressions.RegexOptions.Compiled);

    public static bool IsValidCodeFormat(string code) => CodeFormat.IsMatch(code);

    /// <summary>
    /// Public share link. Uses <see cref="JoinLinkOptions.LinkBaseUrl"/> (api.*) so Android/iOS
    /// App Links stay verified via assetlinks/AASA on that host.
    /// </summary>
    public static string BuildJoinUrl(JoinLinkOptions options, string code)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var baseUrl = options.LinkBaseUrl.TrimEnd('/');
        return $"{baseUrl}/join/{Uri.EscapeDataString(normalized)}";
    }

    /// <summary>Flutter web entry for users who continue in the browser.</summary>
    public static string BuildWebJoinUrl(JoinLinkOptions options, string code)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var baseUrl = options.WebAppUrl.TrimEnd('/');
        return $"{baseUrl}/join/{Uri.EscapeDataString(normalized)}";
    }
}
