using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Quizzes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/quiz-folders")]
[Authorize]
public class QuizFoldersController(IQuizFolderService quizFolderService) : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<QuizFolderDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
    {
        var folders = await quizFolderService.GetMyFoldersAsync(GetUserId(), cancellationToken);
        return Ok(folders);
    }

    [HttpPost]
    [ProducesResponseType(typeof(QuizFolderDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(
        [FromBody] CreateQuizFolderRequest request,
        CancellationToken cancellationToken)
    {
        var folder = await quizFolderService.CreateFolderAsync(GetUserId(), request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { folderId = folder.QuizFolderId }, folder);
    }

    [HttpGet("{folderId:guid}")]
    [ProducesResponseType(typeof(QuizFolderDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(Guid folderId, CancellationToken cancellationToken)
    {
        var folders = await quizFolderService.GetMyFoldersAsync(GetUserId(), cancellationToken);
        var folder = folders.FirstOrDefault(f => f.QuizFolderId == folderId);
        return folder is null ? NotFound() : Ok(folder);
    }

    [HttpPatch("{folderId:guid}")]
    [ProducesResponseType(typeof(QuizFolderDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(
        Guid folderId,
        [FromBody] UpdateQuizFolderRequest request,
        CancellationToken cancellationToken)
    {
        var folder = await quizFolderService.UpdateFolderAsync(
            GetUserId(),
            folderId,
            request,
            cancellationToken);
        return Ok(folder);
    }

    [HttpDelete("{folderId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid folderId, CancellationToken cancellationToken)
    {
        await quizFolderService.DeleteFolderAsync(GetUserId(), folderId, cancellationToken);
        return NoContent();
    }
}
