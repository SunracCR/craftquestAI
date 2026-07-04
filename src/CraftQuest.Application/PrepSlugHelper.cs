using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace CraftQuest.Application;

public static partial class PrepSlugHelper
{
    private static readonly Regex NonSlugChars = SlugSanitizerRegex();

    public static string GenerateFromTitle(string title, Guid catalogItemId)
    {
        var normalized = title.Trim().ToLowerInvariant();
        normalized = normalized
            .Replace('á', 'a').Replace('é', 'e').Replace('í', 'i')
            .Replace('ó', 'o').Replace('ú', 'u').Replace('ñ', 'n').Replace('ü', 'u');
        normalized = NonSlugChars.Replace(normalized, "-");
        normalized = Regex.Replace(normalized, "-{2,}", "-").Trim('-');

        if (string.IsNullOrWhiteSpace(normalized))
        {
            normalized = "prep-item";
        }

        if (normalized.Length > 120)
        {
            normalized = normalized[..120].Trim('-');
        }

        return $"{normalized}-{catalogItemId:N}"[..160];
    }

    [GeneratedRegex(@"[^a-z0-9\-]+", RegexOptions.Compiled)]
    private static partial Regex SlugSanitizerRegex();
}
