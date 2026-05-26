namespace CraftQuest.Application.Models.Media;

public sealed class MediaAssetDto
{
    public required Guid MediaAssetId { get; init; }
    public required string OriginalFileName { get; init; }
    public string? ContentType { get; init; }
    public required string Url { get; init; }
    public long? FileSizeBytes { get; init; }
}
