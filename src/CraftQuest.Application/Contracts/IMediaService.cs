using CraftQuest.Application.Models.Media;

namespace CraftQuest.Application.Contracts;

public interface IMediaService
{
    Task<MediaAssetDto> UploadImageAsync(
        Guid userId,
        Stream content,
        string fileName,
        string contentType,
        long fileSize,
        string? altText = null,
        CancellationToken cancellationToken = default);

    Task<(Stream Stream, string ContentType, string FileName)> OpenReadAsync(
        Guid mediaAssetId,
        CancellationToken cancellationToken = default);

    string BuildPublicUrl(Guid mediaAssetId);
}
