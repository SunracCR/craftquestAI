using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Offline;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/quizzes")]
[Authorize]
public class OfflinePackagesController(IOfflineQuizService offlineQuizService) : ApiControllerBase
{
    [HttpGet("{quizId:guid}/offline-package")]
    [ProducesResponseType(typeof(OfflineQuizPackageDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOfflinePackage(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var package = await offlineQuizService.GetOfflinePackageAsync(
            GetUserId(),
            quizId,
            cancellationToken);
        return Ok(package);
    }
}
