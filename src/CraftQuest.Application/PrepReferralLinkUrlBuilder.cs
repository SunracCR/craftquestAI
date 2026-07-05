using CraftQuest.Application.Options;

namespace CraftQuest.Application;

public static class PrepReferralLinkUrlBuilder
{
    private static readonly System.Text.RegularExpressions.Regex CodeFormat =
        new(@"^PR-\d{6}$", System.Text.RegularExpressions.RegexOptions.Compiled);

    public static bool IsValidCodeFormat(string code) => CodeFormat.IsMatch(code.Trim().ToUpperInvariant());

    public static string ResolvePrepPublicBaseUrl(JoinLinkOptions options) =>
        string.IsNullOrWhiteSpace(options.PublicSiteUrl)
            ? options.LinkBaseUrl.TrimEnd('/')
            : options.PublicSiteUrl.TrimEnd('/');

    public static string BuildPublicLandingUrl(JoinLinkOptions options, string slug)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var baseUrl = ResolvePrepPublicBaseUrl(options);
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}";
    }

    public static string BuildPublicCoverUrl(JoinLinkOptions options, string slug)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var baseUrl = ResolvePrepPublicBaseUrl(options);
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}/cover";
    }

    /// <summary>
    /// URL with a file extension for Open Graph crawlers (Facebook, WhatsApp, etc.).
    /// </summary>
    public static string BuildPublicShareImageUrl(JoinLinkOptions options, string slug)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var baseUrl = ResolvePrepPublicBaseUrl(options);
        return $"{baseUrl}/prep/{Uri.EscapeDataString(normalizedSlug)}/share-image.jpg";
    }

    public static string BuildShareUrl(JoinLinkOptions options, string slug, string referralCode)
    {
        var normalizedSlug = slug.Trim().ToLowerInvariant();
        var normalizedCode = referralCode.Trim().ToUpperInvariant();
        var baseUrl = ResolvePrepPublicBaseUrl(options);
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

    public static string ResolveBrandIconUrl(JoinLinkOptions options)
    {
        if (!string.IsNullOrWhiteSpace(options.BrandIconUrl))
        {
            return options.BrandIconUrl.Trim();
        }

        if (!string.IsNullOrWhiteSpace(options.DefaultOgImageUrl))
        {
            return options.DefaultOgImageUrl.Trim();
        }

        return $"{options.WebAppUrl.TrimEnd('/')}/icons/Icon-192.png";
    }

    public static string ResolveFaviconUrl(JoinLinkOptions options) =>
        $"{options.WebAppUrl.TrimEnd('/')}/favicon-32.png?v=2";
}
