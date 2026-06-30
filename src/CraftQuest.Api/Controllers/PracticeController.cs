using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Teacher;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/practice-sessions")]
[Authorize]
public class PracticeController(IPracticeService practiceService) : ApiControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(PracticeSessionDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Start(
        [FromBody] StartPracticeSessionRequest request,
        CancellationToken cancellationToken)
    {
        var session = await practiceService.StartSessionAsync(GetUserId(), request, cancellationToken);
        return CreatedAtAction(nameof(Start), new { sessionId = session.PracticeSessionId }, session);
    }

    [HttpPost("{sessionId:guid}/questions/{practiceQuestionSnapshotId:guid}/answer")]
    [ProducesResponseType(typeof(SubmitAnswerResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> SubmitAnswer(
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        [FromBody] SubmitAnswerRequest request,
        CancellationToken cancellationToken)
    {
        var result = await practiceService.SubmitAnswerAsync(
            GetUserId(),
            sessionId,
            practiceQuestionSnapshotId,
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("{sessionId:guid}/finish")]
    [ProducesResponseType(typeof(PracticeSessionResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Finish(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var result = await practiceService.FinishSessionAsync(GetUserId(), sessionId, cancellationToken);
        return Ok(result);
    }

    [HttpGet("active")]
    [ProducesResponseType(typeof(PracticeActiveSessionSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> GetActiveForQuiz(
        [FromQuery] Guid quizId,
        [FromQuery] Guid? assignmentId,
        CancellationToken cancellationToken)
    {
        var summary = await practiceService.GetActiveSessionForQuizAsync(
            GetUserId(),
            quizId,
            assignmentId,
            cancellationToken);

        return summary is null ? NoContent() : Ok(summary);
    }

    [HttpGet("in-progress")]
    [ProducesResponseType(typeof(IReadOnlyList<PracticeActiveSessionSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetInProgress(CancellationToken cancellationToken)
    {
        var sessions = await practiceService.GetInProgressSessionsAsync(
            GetUserId(),
            cancellationToken);
        return Ok(sessions);
    }

    [HttpGet("{sessionId:guid}")]
    [ProducesResponseType(typeof(PracticeSessionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSession(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var session = await practiceService.GetSessionAsync(GetUserId(), sessionId, cancellationToken);
        return Ok(session);
    }

    [HttpGet("{sessionId:guid}/questions/{practiceQuestionSnapshotId:guid}")]
    [ProducesResponseType(typeof(PracticeQuestionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSessionQuestion(
        Guid sessionId,
        Guid practiceQuestionSnapshotId,
        CancellationToken cancellationToken)
    {
        var question = await practiceService.GetSessionQuestionAsync(
            GetUserId(),
            sessionId,
            practiceQuestionSnapshotId,
            cancellationToken);
        return Ok(question);
    }

    [HttpPatch("{sessionId:guid}/progress")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateProgress(
        Guid sessionId,
        [FromBody] UpdatePracticeProgressRequest request,
        CancellationToken cancellationToken)
    {
        await practiceService.UpdateProgressAsync(
            GetUserId(),
            sessionId,
            request,
            cancellationToken);
        return NoContent();
    }

    [HttpPost("{sessionId:guid}/abandon")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Abandon(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        await practiceService.AbandonSessionAsync(GetUserId(), sessionId, cancellationToken);
        return NoContent();
    }

    [HttpPost("{sessionId:guid}/forfeit")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Forfeit(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        await practiceService.ForfeitSessionAsync(GetUserId(), sessionId, cancellationToken);
        return NoContent();
    }

    [HttpGet("by-quiz/{quizId:guid}/my-attempts")]
    [ProducesResponseType(typeof(IReadOnlyList<MyPracticeAttemptSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListMyQuizAttempts(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var attempts = await practiceService.ListMyQuizAttemptsAsync(
            GetUserId(),
            quizId,
            cancellationToken);
        return Ok(attempts);
    }

    [HttpGet("{sessionId:guid}/my-review")]
    [ProducesResponseType(typeof(TeacherPracticeReviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMySessionReview(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var review = await practiceService.GetMySessionReviewAsync(
            GetUserId(),
            sessionId,
            cancellationToken);
        return Ok(review);
    }

    [HttpGet("by-quiz/{quizId:guid}/my-analytics")]
    [ProducesResponseType(typeof(MyQuizPracticeAnalyticsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyQuizAnalytics(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var analytics = await practiceService.GetMyQuizPracticeAnalyticsAsync(
            GetUserId(),
            quizId,
            cancellationToken);
        return Ok(analytics);
    }
}
