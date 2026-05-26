using System.Security.Cryptography;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Media;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Media;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class MediaService(
    CraftQuestDbContext dbContext,
    IServiceProvider serviceProvider,
    IOptions<MediaOptions> options) : IMediaService
{
    public async Task<MediaAssetDto> UploadImageAsync(
        Guid userId,
        Stream content,
        string fileName,
        string contentType,
        long fileSize,
        string? altText = null,
        CancellationToken cancellationToken = default)
    {
        var mediaOptions = options.Value;
        if (fileSize <= 0)
        {
            throw new AppException("File is empty.", 400);
        }

        if (fileSize > mediaOptions.MaxUploadBytes)
        {
            throw new AppException(
                $"File exceeds maximum size of {mediaOptions.MaxUploadBytes} bytes.",
                400);
        }

        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        if (!mediaOptions.AllowedImageExtensions.Contains(extension))
        {
            throw new AppException("Unsupported image file type.", 400);
        }

        var storage = ResolveStorageProvider();
        var mediaId = Guid.NewGuid();
        var blobPath = $"{mediaId:N}{extension}";

        await storage.SaveAsync(blobPath, content, contentType, cancellationToken);

        var hash = await ComputeSha256Async(storage, blobPath, cancellationToken);

        var entity = new MediaAsset
        {
            MediaAssetId = mediaId,
            UploadedByUserId = userId,
            StorageProvider = storage.ProviderCode,
            ContainerName = storage.ProviderCode == "azure"
                ? mediaOptions.Azure.ContainerName
                : "media",
            BlobPath = blobPath,
            OriginalFileName = Path.GetFileName(fileName),
            ContentType = contentType,
            FileExtension = extension,
            FileSizeBytes = fileSize,
            Sha256Hash = hash,
            AltText = altText,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.MediaAssets.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapDto(entity);
    }

    public async Task<(Stream Stream, string ContentType, string FileName)> OpenReadAsync(
        Guid mediaAssetId,
        CancellationToken cancellationToken = default)
    {
        var asset = await dbContext.MediaAssets
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.MediaAssetId == mediaAssetId && m.Status == "active", cancellationToken)
            ?? throw new AppException("Media asset not found.", 404);

        var storage = ResolveStorageProvider(asset.StorageProvider);
        if (!storage.Exists(asset.BlobPath))
        {
            throw new AppException("Media file is missing on storage.", 404);
        }

        var stream = await storage.OpenReadAsync(asset.BlobPath, cancellationToken);
        return (stream, asset.ContentType ?? "application/octet-stream", asset.OriginalFileName);
    }

    public string BuildPublicUrl(Guid mediaAssetId) =>
        $"{options.Value.PublicBasePath.TrimEnd('/')}/{mediaAssetId}/file";

    private IMediaStorageProvider ResolveStorageProvider(string? providerCode = null)
    {
        var code = (providerCode ?? options.Value.StorageProvider).Trim().ToLowerInvariant();
        return code switch
        {
            "azure" => serviceProvider.GetRequiredService<AzureBlobMediaStorageProvider>(),
            _ => serviceProvider.GetRequiredService<LocalMediaStorageProvider>(),
        };
    }

    private static async Task<string> ComputeSha256Async(
        IMediaStorageProvider storage,
        string blobPath,
        CancellationToken cancellationToken)
    {
        await using var stream = await storage.OpenReadAsync(blobPath, cancellationToken);
        var hash = await SHA256.HashDataAsync(stream, cancellationToken);
        return Convert.ToHexString(hash);
    }

    private MediaAssetDto MapDto(MediaAsset asset) => new()
    {
        MediaAssetId = asset.MediaAssetId,
        OriginalFileName = asset.OriginalFileName,
        ContentType = asset.ContentType,
        Url = BuildPublicUrl(asset.MediaAssetId),
        FileSizeBytes = asset.FileSizeBytes,
    };
}
