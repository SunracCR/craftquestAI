using Microsoft.AspNetCore.Mvc;
using Microsoft.Net.Http.Headers;

namespace CraftQuest.Api.Services;

internal static class SocialPreviewImageResult
{
    public static IActionResult FromStream(
        Stream stream,
        string contentType,
        long? fileSizeBytes = null)
    {
        var normalizedType = string.IsNullOrWhiteSpace(contentType)
            ? "image/jpeg"
            : contentType;

        return new FileStreamResult(stream, normalizedType)
        {
            EnableRangeProcessing = true,
            EntityTag = fileSizeBytes is > 0
                ? new EntityTagHeaderValue($"\"{fileSizeBytes.Value}\"")
                : null,
            LastModified = DateTime.UtcNow,
        };
    }

    public static void ApplySocialCacheHeaders(HttpResponse response, long? fileSizeBytes)
    {
        response.Headers[HeaderNames.CacheControl] = "public, max-age=86400, immutable";
        response.Headers[HeaderNames.ContentDisposition] = "inline";
        if (fileSizeBytes is > 0)
        {
            response.ContentLength = fileSizeBytes.Value;
        }
    }
}
