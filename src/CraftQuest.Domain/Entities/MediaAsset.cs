namespace CraftQuest.Domain.Entities;

public class MediaAsset
{
    public Guid MediaAssetId { get; set; }
    public Guid UploadedByUserId { get; set; }
    public string StorageProvider { get; set; } = "local";
    public string ContainerName { get; set; } = "media";
    public string BlobPath { get; set; } = string.Empty;
    public string OriginalFileName { get; set; } = string.Empty;
    public string? ContentType { get; set; }
    public string? FileExtension { get; set; }
    public long? FileSizeBytes { get; set; }
    public string? Sha256Hash { get; set; }
    public string? AltText { get; set; }
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; }

    public User UploadedByUser { get; set; } = null!;
}
