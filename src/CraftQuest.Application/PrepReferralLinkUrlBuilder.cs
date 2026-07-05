using CraftQuest.Application.Options;

namespace CraftQuest.Application;

public static class PrepReferralLinkUrlBuilder
{
    private static readonly System.Text.RegularExpressions.Regex CodeFormat =
        new(@"^PR-\d{6}$", System.Text.RegularExpressions.RegexOptions.Compiled);

    public static bool IsValidCodeFormat(string code) => CodeFormat.IsMatch(code.Trim().ToUpperInvariant());

    public static string BuildPublicLandingUrl(JoinLinkOptions options, string slug)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var baseUrl = options.LinkBaseUrl.TrimEnd('/');
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}";
    }

    public static string BuildShareUrl(JoinLinkOptions options, string slug, string referralCode)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var normalizedCode = referralCode.Trim().ToUpperInvariant();
        var baseUrl = options.LinkBaseUrl.TrimEnd('/');
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}?ref={Uri.EscapeDataString(normalizedCode)}";
    }

    public static string BuildWebUrl(JoinLinkOptions options, string slug, string? referralCode)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var baseUrl = options.WebAppUrl.TrimEnd('/');
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}";
        }

        var normalizedCode = referralCode.Trim().ToUpperInvariant();
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}?ref={Uri.EscapeDataString(normalizedCode)}";
    }

    public static string BuildDeepLink(string slug, string? referralCode)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            return $"craftquest://prep/{Uri.EscapeDataString(normalizedSlug)}";
        }

        var normalizedCode = referralCode.Trim().ToUpperInvariant();
        return $"craftquest://prep/{Uri.EscapeDataString(normalizedSlug)}?ref={Uri.EscapeDataString(normalizedCode)}";
    }

    public static string ToAbsoluteUrl(JoinLinkOptions options, string pathOrAbsolute)
    {
        if (string.IsNullOrWhiteSpace(pathOrAbsolute))
        {
            return pathOrAbsolute;
        }

        if (pathOrAbsolute.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || pathOrAbsolute.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return pathOrAbsolute;
        }

        var path = pathOrAbsolute.StartsWith('/') ? pathOrAbsolute : $"/{pathOrAbsolute}";
        return $"{options.LinkBaseUrl.TrimEnd('/')}{path}";
    }
}
