using CraftQuest.Application.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/question-types")]
[Authorize]
public class QuestionTypesController(IQuizService quizService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var types = await quizService.GetQuestionTypesAsync(cancellationToken);
        return Ok(types);
    }
}
