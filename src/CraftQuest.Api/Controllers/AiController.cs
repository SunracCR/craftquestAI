using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Ai;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.StudyMaterials;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize]
public class AiController(
    IAiService aiService,
    IQuizGenerationService quizGenerationService) : ApiControllerBase
{
    [HttpPost("question-format/normalize")]
    [ProducesResponseType(typeof(AiNormalizeRawTextResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> NormalizeRawText(
        [FromBody] AiNormalizeRawTextRequest request,
        CancellationToken cancellationToken)
    {
        var result = await aiService.NormalizeRawTextAsync(
            GetUserId(),
            request,
            cancellationToken);

        return Ok(result);
    }

    [HttpDelete("jobs/inbox-history")]
    [ProducesResponseType(typeof(ClearAiInboxHistoryResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> ClearInboxHistory(CancellationToken cancellationToken)
    {
        var removed = await aiService.ClearInboxHistoryAsync(GetUserId(), cancellationToken);
        return Ok(new ClearAiInboxHistoryResultDto { RemovedCount = removed });
    }

    [HttpGet("jobs")]
    [ProducesResponseType(typeof(IReadOnlyList<AiJobSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListJobs(
        [FromQuery] string filter = "inbox",
        CancellationToken cancellationToken = default)
    {
        var jobs = await aiService.ListJobsAsync(GetUserId(), filter, cancellationToken);
        return Ok(jobs);
    }

    [HttpGet("jobs/{aiJobId:guid}")]
    [ProducesResponseType(typeof(AiJobDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetJob(Guid aiJobId, CancellationToken cancellationToken)
    {
        var job = await aiService.GetJobAsync(GetUserId(), aiJobId, cancellationToken);
        return Ok(job);
    }

    [HttpPost("jobs/{aiJobId:guid}/retry")]
    [ProducesResponseType(typeof(StartQuizGenerationResultDto), StatusCodes.Status202Accepted)]
    public async Task<IActionResult> RetryJob(Guid aiJobId, CancellationToken cancellationToken)
    {
        var result = await quizGenerationService.RetryGenerationJobAsync(
            GetUserId(),
            aiJobId,
            cancellationToken);
        return Accepted(result);
    }
}
