using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Media;

public class LocalMediaStorageProvider(
    IHostEnvironment hostEnvironment,
    IOptions<MediaOptions> options) : IMediaStorageProvider
{
    public string ProviderCode => "local";

    public async Task SaveAsync(
        string blobPath,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var absolutePath = GetAbsolutePath(blobPath);
        Directory.CreateDirectory(Path.GetDirectoryName(absolutePath)!);

        await using var fileStream = new FileStream(
            absolutePath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            4096,
            true);

        await content.CopyToAsync(fileStream, cancellationToken);
    }

    public Task<Stream> OpenReadAsync(
        string blobPath,
        CancellationToken cancellationToken = default)
    {
        var absolutePath = GetAbsolutePath(blobPath);
        if (!File.Exists(absolutePath))
        {
            throw new FileNotFoundException("Media file not found.", absolutePath);
        }

        Stream stream = new FileStream(
            absolutePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            4096,
            true);

        return Task.FromResult(stream);
    }

    public bool Exists(string blobPath) => File.Exists(GetAbsolutePath(blobPath));

    public Task DeleteIfExistsAsync(
        string blobPath,
        CancellationToken cancellationToken = default)
    {
        var absolutePath = GetAbsolutePath(blobPath);
        if (File.Exists(absolutePath))
        {
            File.Delete(absolutePath);
        }

        return Task.CompletedTask;
    }

    private string GetAbsolutePath(string blobPath) =>
        Path.Combine(hostEnvironment.ContentRootPath, options.Value.LocalRootPath, blobPath);
}
