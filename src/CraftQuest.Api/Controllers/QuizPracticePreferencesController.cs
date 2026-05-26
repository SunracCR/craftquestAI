using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Practice;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/quizzes/{quizId:guid}/practice-preferences")]
public class QuizPracticePreferencesController(
    IQuizPracticePreferenceService preferenceService) : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(QuizPracticePreferenceDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(Guid quizId, CancellationToken cancellationToken)
    {
        var preference = await preferenceService.GetAsync(GetUserId(), quizId, cancellationToken);
        return Ok(preference);
    }

    [HttpPut]
    [ProducesResponseType(typeof(QuizPracticePreferenceDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Upsert(
        Guid quizId,
        [FromBody] UpsertQuizPracticePreferenceRequest request,
        CancellationToken cancellationToken)
    {
        var preference = await preferenceService.UpsertAsync(
            GetUserId(),
            quizId,
            request,
            cancellationToken);
        return Ok(preference);
    }
}
