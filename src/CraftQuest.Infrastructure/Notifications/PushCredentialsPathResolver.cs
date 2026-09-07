namespace CraftQuest.Infrastructure.Notifications;

internal static class PushCredentialsPathResolver
{
    internal static readonly string[] DefaultCandidatePaths =
    [
        "/home/site/secrets/firebase-credentials.json",
        "/home/secrets/firebase-credentials.json",
        "/var/secrets/firebase-credentials.json",
        @"D:\home\site\secrets\firebase-credentials.json",
        @"D:\home\secrets\firebase-credentials.json",
    ];

    public static string? Resolve(string? configuredPath, Func<string, bool>? exists = null)
    {
        exists ??= File.Exists;
        var candidates = new List<string>();
        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            var trimmed = configuredPath.Trim();
            candidates.Add(trimmed);
            var mapped = MapAzureWindowsPathToLinux(trimmed);
            if (mapped is not null)
            {
                candidates.Add(mapped);
            }
        }

        candidates.AddRange(DefaultCandidatePaths);

        foreach (var path in candidates.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (exists(path))
            {
                return path;
            }
        }

        return null;
    }

    internal static string? MapAzureWindowsPathToLinux(string path)
    {
        var normalized = path.Replace('\\', '/');
        const string prefix = "D:/home/";
        if (!normalized.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return "/home/" + normalized[prefix.Length..];
    }
}
