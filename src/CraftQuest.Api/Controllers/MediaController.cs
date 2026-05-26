using CraftQuest.Application.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/media")]
public class MediaController(IMediaService mediaService) : ApiControllerBase
{
    [HttpPost("upload")]
    [Authorize]
    [RequestSizeLimit(6_000_000)]
    [ProducesResponseType(typeof(Application.Models.Media.MediaAssetDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Upload(
        IFormFile file,
        [FromForm] string? altText,
        CancellationToken cancellationToken)
    {
        await using var stream = file.OpenReadStream();
        var asset = await mediaService.UploadImageAsync(
            GetUserId(),
            stream,
            file.FileName,
            file.ContentType,
            file.Length,
            altText,
            cancellationToken);

        return Created(asset.Url, asset);
    }

    [HttpGet("{mediaAssetId:guid}/file")]
    [AllowAnonymous]
    public async Task<IActionResult> GetFile(
        Guid mediaAssetId,
        CancellationToken cancellationToken)
    {
        var (stream, contentType, fileName) =
            await mediaService.OpenReadAsync(mediaAssetId, cancellationToken);

        return File(stream, contentType, fileName);
    }
}
