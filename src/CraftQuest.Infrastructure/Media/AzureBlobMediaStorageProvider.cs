using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Media;

public class AzureBlobMediaStorageProvider(IOptions<MediaOptions> options) : IMediaStorageProvider
{
    private readonly MediaOptions _options = options.Value;

    public string ProviderCode => "azure";

    public async Task SaveAsync(
        string blobPath,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var client = GetBlobClient(blobPath);
        await client.UploadAsync(
            content,
            new BlobUploadOptions
            {
                HttpHeaders = new BlobHttpHeaders { ContentType = contentType },
            },
            cancellationToken);
    }

    public async Task<Stream> OpenReadAsync(
        string blobPath,
        CancellationToken cancellationToken = default)
    {
        var client = GetBlobClient(blobPath);
        if (!await client.ExistsAsync(cancellationToken))
        {
            throw new FileNotFoundException($"Blob '{blobPath}' was not found.");
        }

        var response = await client.DownloadStreamingAsync(cancellationToken: cancellationToken);
        return response.Value.Content;
    }

    public bool Exists(string blobPath) =>
        GetBlobClient(blobPath).Exists().Value;

    public async Task DeleteIfExistsAsync(
        string blobPath,
        CancellationToken cancellationToken = default)
    {
        var client = GetBlobClient(blobPath);
        await client.DeleteIfExistsAsync(cancellationToken: cancellationToken);
    }

    private BlobClient GetBlobClient(string blobPath)
    {
        if (string.IsNullOrWhiteSpace(_options.Azure.ConnectionString))
        {
            throw new InvalidOperationException(
                "Media:Azure:ConnectionString is required when StorageProvider is 'azure'.");
        }

        var container = _options.Azure.ContainerName;
        var serviceClient = new BlobServiceClient(_options.Azure.ConnectionString);
        return serviceClient.GetBlobContainerClient(container).GetBlobClient(blobPath);
    }
}
