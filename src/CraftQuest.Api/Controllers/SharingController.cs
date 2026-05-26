using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Sharing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/sharing")]
[Authorize]
public class SharingController(IShareCodeService shareCodeService) : ApiControllerBase
{
    [HttpPost("share-codes/redeem")]
    [ProducesResponseType(typeof(RedeemShareCodeResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Redeem(
        [FromBody] RedeemShareCodeRequest request,
        CancellationToken cancellationToken)
    {
        var result = await shareCodeService.RedeemAsync(GetUserId(), request, cancellationToken);
        return Ok(result);
    }

    [HttpGet("accessible-quizzes")]
    [ProducesResponseType(typeof(IReadOnlyList<AccessibleQuizDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAccessibleQuizzes(CancellationToken cancellationToken)
    {
        var quizzes = await shareCodeService.GetAccessibleQuizzesAsync(
            GetUserId(),
            cancellationToken);

        return Ok(quizzes);
    }

    [HttpDelete("accessible-quizzes/{quizId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RemoveAccessibleQuiz(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        await shareCodeService.RemoveAccessibleQuizAsync(GetUserId(), quizId, cancellationToken);
        return NoContent();
    }
}
