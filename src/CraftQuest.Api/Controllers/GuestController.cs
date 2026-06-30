using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Guest;
using CraftQuest.Application.Models.Practice;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/guest")]
[AllowAnonymous]
public class GuestController(IGuestService guestService) : ControllerBase
{
    private string GuestToken => Request.Headers["X-Guest-Token"].ToString();

    [HttpPost("enter")]
    [ProducesResponseType(typeof(GuestVisitDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Enter(
        [FromBody] GuestEnterRequest request,
        CancellationToken cancellationToken)
    {
        var visit = await guestService.EnterAsync(request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, visit);
    }

    [HttpGet("visit")]
    [ProducesResponseType(typeof(GuestVisitDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVisit(CancellationToken cancellationToken)
    {
        var token = GuestToken;
        if (string.IsNullOrWhiteSpace(token))
        {
            return NotFound();
        }

        var visit = await guestService.GetVisitAsync(token, cancellationToken);
        return visit is null ? NotFound() : Ok(visit);
    }

    [HttpPost("{visitId:guid}/practice/start")]
    [ProducesResponseType(typeof(PracticeSessionDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> StartPractice(
        Guid visitId,
        [FromBody] GuestStartPracticeRequest request,
        CancellationToken cancellationToken)
    {
        var session = await guestService.StartPracticeAsync(visitId, GuestToken, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, session);
    }

    [HttpGet("{visitId:guid}/practice/active")]
    [ProducesResponseType(typeof(PracticeActiveSessionSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetActiveSession(
        Guid visitId,
        CancellationToken cancellationToken)
    {
        var session = await guestService.GetActiveSessionAsync(visitId, GuestToken, cancellationToken);
        return session is null ? NotFound() : Ok(session);
    }

    [HttpPost("{visitId:guid}/practice/{sessionId:guid}/abandon")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> AbandonSession(
        Guid visitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        await guestService.AbandonSessionAsync(visitId, GuestToken, sessionId, cancellationToken);
        return NoContent();
    }

    [HttpGet("{visitId:guid}/practice/{sessionId:guid}")]
    [ProducesResponseType(typeof(PracticeSessionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSession(
        Guid visitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var session = await guestService.GetSessionAsync(visitId, GuestToken, sessionId, cancellationToken);
        return Ok(session);
    }

    [HttpGet("{visitId:guid}/practice/{sessionId:guid}/questions/{snapshotId:guid}")]
    [ProducesResponseType(typeof(PracticeQuestionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSessionQuestion(
        Guid visitId,
        Guid sessionId,
        Guid snapshotId,
        CancellationToken cancellationToken)
    {
        var question = await guestService.GetSessionQuestionAsync(
            visitId,
            GuestToken,
            sessionId,
            snapshotId,
            cancellationToken);
        return Ok(question);
    }

    [HttpPost("{visitId:guid}/practice/{sessionId:guid}/questions/{snapshotId:guid}/answer")]
    [ProducesResponseType(typeof(SubmitAnswerResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> SubmitAnswer(
        Guid visitId,
        Guid sessionId,
        Guid snapshotId,
        [FromBody] SubmitAnswerRequest request,
        CancellationToken cancellationToken)
    {
        var result = await guestService.SubmitAnswerAsync(
            visitId, GuestToken, sessionId, snapshotId, request, cancellationToken);
        return Ok(result);
    }

    [HttpPatch("{visitId:guid}/practice/{sessionId:guid}/progress")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateProgress(
        Guid visitId,
        Guid sessionId,
        [FromBody] UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken)
    {
        await guestService.UpdateProgressAsync(visitId, GuestToken, sessionId, request, cancellationToken);
        return NoContent();
    }

    [HttpPost("{visitId:guid}/practice/{sessionId:guid}/finish")]
    [ProducesResponseType(typeof(Application.Models.Practice.PracticeSessionResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> FinishSession(
        Guid visitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var result = await guestService.FinishSessionAsync(visitId, GuestToken, sessionId, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{visitId:guid}/attempts")]
    [ProducesResponseType(typeof(IReadOnlyList<GuestAttemptSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListAttempts(
        Guid visitId,
        CancellationToken cancellationToken)
    {
        var attempts = await guestService.ListAttemptsAsync(visitId, GuestToken, cancellationToken);
        return Ok(attempts);
    }

    [HttpGet("{visitId:guid}/attempts/{sessionId:guid}/review")]
    [ProducesResponseType(typeof(Application.Models.Teacher.TeacherPracticeReviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAttemptReview(
        Guid visitId,
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var review = await guestService.GetAttemptReviewAsync(visitId, GuestToken, sessionId, cancellationToken);
        return Ok(review);
    }

    [HttpDelete("{visitId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Leave(
        Guid visitId,
        CancellationToken cancellationToken)
    {
        await guestService.LeaveAsync(visitId, GuestToken, cancellationToken);
        return NoContent();
    }
}
