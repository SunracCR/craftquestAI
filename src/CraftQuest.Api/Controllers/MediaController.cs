using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/media")]
public class MediaController(
    IMediaService mediaService,
    IMediaAccessService mediaAccessService) : ApiControllerBase
{
    [HttpPost("upload")]
    [Authorize]
    [RequestSizeLimit(6_000_000)]
    [ProducesResponseType(typeof(Application.Models.Media.MediaAssetDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Upload(
        [FromForm] IFormFile? file,
        [FromForm] string? altText,
        CancellationToken cancellationToken)
    {
        if (file == null || file.Length == 0)
        {
            throw new AppException("Image file is required.", 400);
        }

        await using var stream = file.OpenReadStream();
        var asset = await mediaService.UploadImageAsync(
            GetUserId(),
            stream,
            file.FileName,
            file.ContentType ?? "application/octet-stream",
            file.Length,
            altText,
            cancellationToken);

        // Cuerpo JSON explícito (Created(uri, dto) a veces deja el body vacío en clientes móviles).
        return StatusCode(StatusCodes.Status201Created, asset);
    }

    /// <summary>
    /// Requiere JWT o cabeceras de invitado (<c>X-Guest-Token</c> + <c>X-Guest-Visit-Id</c>).
    /// La imagen debe pertenecer a un cuestionario al que el caller tiene acceso.
    /// </summary>
    [HttpGet("{mediaAssetId:guid}/file")]
    [AllowAnonymous]
    public async Task<IActionResult> GetFile(
        Guid mediaAssetId,
        CancellationToken cancellationToken)
    {
        Guid? userId = null;
        if (User.Identity?.IsAuthenticated == true)
        {
            userId = GetUserId();
        }

        Guid? guestVisitId = null;
        if (Guid.TryParse(Request.Headers["X-Guest-Visit-Id"].FirstOrDefault(), out var parsedVisitId))
        {
            guestVisitId = parsedVisitId;
        }

        var guestToken = Request.Headers["X-Guest-Token"].FirstOrDefault();

        await mediaAccessService.EnsureCanReadAsync(
            mediaAssetId,
            userId,
            guestVisitId,
            guestToken,
            cancellationToken);

        var (stream, contentType, fileName) =
            await mediaService.OpenReadAsync(mediaAssetId, cancellationToken);

        SocialPreviewImageResult.ApplySocialCacheHeaders(Response, null);
        return SocialPreviewImageResult.FromStream(stream, contentType);
    }
}
