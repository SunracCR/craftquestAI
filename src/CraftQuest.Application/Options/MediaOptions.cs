namespace CraftQuest.Application.Options;

public class MediaOptions
{
    public const string SectionName = "Media";

    /// <summary>local | azure</summary>
    public string StorageProvider { get; set; } = "local";

    public string LocalRootPath { get; set; } = "App_Data/media";
    public string PublicBasePath { get; set; } = "/api/media";
    public long MaxUploadBytes { get; set; } = 5_242_880;
    public string[] AllowedImageExtensions { get; set; } = [".jpg", ".jpeg", ".png", ".webp", ".gif"];

    public AzureBlobMediaOptions Azure { get; set; } = new();
}

public class AzureBlobMediaOptions
{
    public string ConnectionString { get; set; } = string.Empty;
    public string ContainerName { get; set; } = "craftquest-media";
}
