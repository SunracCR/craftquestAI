using CraftQuest.Application.Options;

namespace CraftQuest.Application;

public static class JoinLinkUrlBuilder
{
    private static readonly System.Text.RegularExpressions.Regex CodeFormat =
        new(@"^CQ-\d{6}$", System.Text.RegularExpressions.RegexOptions.Compiled);

    public static bool IsValidCodeFormat(string code) => CodeFormat.IsMatch(code);

    public static string BuildJoinUrl(JoinLinkOptions options, string code)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var baseUrl = options.LinkBaseUrl.TrimEnd('/');
        return $"{baseUrl}/join/{Uri.EscapeDataString(normalized)}";
    }

    public static string BuildWebJoinUrl(JoinLinkOptions options, string code)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var baseUrl = options.WebAppUrl.TrimEnd('/');
        return $"{baseUrl}/join?code={Uri.EscapeDataString(normalized)}";
    }
}
