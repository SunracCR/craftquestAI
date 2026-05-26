using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Sharing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/quizzes/{quizId:guid}")]
[Authorize]
public class ShareCodesController(IShareCodeService shareCodeService) : ApiControllerBase
{
    [HttpGet("share-code")]
    [ProducesResponseType(typeof(ShareCodeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var shareCode = await shareCodeService.GetQuizShareCodeAsync(
            GetUserId(),
            quizId,
            cancellationToken);

        return shareCode is null ? NotFound() : Ok(shareCode);
    }

    [HttpPost("share-code")]
    [HttpPost("share-codes")]
    [ProducesResponseType(typeof(ShareCodeDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Ensure(
        Guid quizId,
        [FromBody] CreateShareCodeRequest request,
        CancellationToken cancellationToken)
    {
        var shareCode = await shareCodeService.CreateShareCodeAsync(
            GetUserId(),
            quizId,
            request,
            cancellationToken);

        return Ok(shareCode);
    }

    [HttpPost("invitations")]
    [ProducesResponseType(typeof(InviteUsersResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> InviteUsers(
        Guid quizId,
        [FromBody] InviteUsersRequest request,
        CancellationToken cancellationToken)
    {
        var result = await shareCodeService.InviteUsersByEmailAsync(
            GetUserId(),
            quizId,
            request,
            cancellationToken);

        return Ok(result);
    }
}
