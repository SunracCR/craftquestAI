using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.PrepPlus;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/prep/public")]
[AllowAnonymous]
public class PrepPublicController(IPrepPlusCatalogService prepPlusCatalogService) : ControllerBase
{
    [HttpGet("items/{slug}")]
    [ProducesResponseType(typeof(PrepPublicPreviewDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPublicPreview(string slug, CancellationToken cancellationToken)
    {
        var preview = await prepPlusCatalogService.GetPublicPreviewBySlugAsync(slug, cancellationToken);
        return preview is null ? NotFound() : Ok(preview);
    }
}
