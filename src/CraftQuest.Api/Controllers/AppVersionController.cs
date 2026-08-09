using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.AppVersion;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

/// <summary>
/// Requisitos de versión mínima de la app móvil, usados por el cliente para
/// forzar actualización. Lectura pública (sin auth: debe funcionar incluso sin
/// sesión o con token vencido); escritura restringida a super admin.
/// </summary>
[ApiController]
[Route("api/app-version")]
public class AppVersionController(IAppVersionService appVersionService) : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get([FromQuery] string platform, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(platform))
        {
            return BadRequest(new { message = "platform is required." });
        }

        var requirement = await appVersionService.GetRequirementAsync(platform, cancellationToken);
        if (requirement is null)
        {
            return NotFound();
        }

        return Ok(requirement);
    }

    [HttpPut("{platform}")]
    [Authorize(Policy = "SuperAdmin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Upsert(
        string platform,
        [FromBody] UpsertAppVersionRequirementDto request,
        CancellationToken cancellationToken)
    {
        var result = await appVersionService.UpsertRequirementAsync(platform, request, cancellationToken);
        return Ok(result);
    }
}
