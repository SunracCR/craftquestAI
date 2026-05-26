namespace CraftQuest.Application.Contracts;

public interface IMediaStorageProvider
{
    string ProviderCode { get; }

    Task SaveAsync(
        string blobPath,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default);

    Task<Stream> OpenReadAsync(
        string blobPath,
        CancellationToken cancellationToken = default);

    bool Exists(string blobPath);

    Task DeleteIfExistsAsync(
        string blobPath,
        CancellationToken cancellationToken = default);
}
