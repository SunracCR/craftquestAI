namespace CraftQuest.Infrastructure.StudyMaterials;

internal static class StudyMaterialStreamHelper
{
    /// <summary>
    /// PdfPig and Open XML require seekable streams. Azure blob downloads are forward-only.
    /// </summary>
    public static async Task<Stream> OpenSeekableCopyAsync(
        Stream content,
        CancellationToken cancellationToken = default)
    {
        if (content.CanSeek)
        {
            content.Position = 0;
            return content;
        }

        var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;
        return buffer;
    }
}
