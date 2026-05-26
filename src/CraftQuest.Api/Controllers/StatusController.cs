using CraftQuest.Application.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/status")]
public class StatusController(IAppStatusService appStatusService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        var status = await appStatusService.GetStatusAsync(cancellationToken);
        return Ok(status);
    }
}