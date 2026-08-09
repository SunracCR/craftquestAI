namespace CraftQuest.Application.Models.AppVersion;

public sealed class AppVersionRequirementDto
{
    public required string Platform { get; init; }
    public required string MinSupportedVersion { get; init; }
    public string? LatestVersion { get; init; }
    public required string UpdateUrl { get; init; }
    public string? Message { get; init; }
}

public sealed class UpsertAppVersionRequirementDto
{
    public required string MinSupportedVersion { get; init; }
    public string? LatestVersion { get; init; }
    public required string UpdateUrl { get; init; }
    public string? Message { get; init; }
}
