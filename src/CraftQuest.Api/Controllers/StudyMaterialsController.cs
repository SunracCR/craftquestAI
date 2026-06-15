using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.StudyMaterials;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/study-materials")]
[Authorize]
public class StudyMaterialsController(
    IStudyMaterialService studyMaterialService,
    IQuizGenerationService quizGenerationService) : ApiControllerBase
{
    [HttpPost]
    [RequestSizeLimit(26_214_400)]
    [ProducesResponseType(typeof(StudyMaterialUploadResultDto), StatusCodes.Status202Accepted)]
    public async Task<IActionResult> Upload(
        IFormFile file,
        [FromForm] string? title,
        CancellationToken cancellationToken)
    {
        if (file is null || file.Length == 0)
        {
            return BadRequest(new { title = "File is empty." });
        }

        await using var stream = file.OpenReadStream();
        var result = await studyMaterialService.UploadAsync(
            GetUserId(),
            stream,
            file.FileName,
            file.ContentType,
            file.Length,
            title,
            cancellationToken);

        return Accepted(result);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<StudyMaterialSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var items = await studyMaterialService.ListAsync(GetUserId(), skip, take, cancellationToken);
        return Ok(items);
    }

    [HttpGet("{studyMaterialId:guid}")]
    [ProducesResponseType(typeof(StudyMaterialDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(Guid studyMaterialId, CancellationToken cancellationToken)
    {
        var detail = await studyMaterialService.GetAsync(GetUserId(), studyMaterialId, cancellationToken);
        return Ok(detail);
    }

    [HttpPatch("{studyMaterialId:guid}/extracted-text")]
    [ProducesResponseType(typeof(StudyMaterialDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateExtractedText(
        Guid studyMaterialId,
        [FromBody] UpdateStudyMaterialExtractedTextRequest request,
        CancellationToken cancellationToken)
    {
        var detail = await studyMaterialService.UpdateExtractedTextAsync(
            GetUserId(),
            studyMaterialId,
            request,
            cancellationToken);
        return Ok(detail);
    }

    [HttpPatch("{studyMaterialId:guid}/selection")]
    [ProducesResponseType(typeof(StudyMaterialDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateSelection(
        Guid studyMaterialId,
        [FromBody] UpdateStudyMaterialSelectionRequest request,
        CancellationToken cancellationToken)
    {
        var detail = await studyMaterialService.UpdateSelectionAsync(
            GetUserId(),
            studyMaterialId,
            request,
            cancellationToken);
        return Ok(detail);
    }

    [HttpDelete("{studyMaterialId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid studyMaterialId, CancellationToken cancellationToken)
    {
        await studyMaterialService.DeleteAsync(GetUserId(), studyMaterialId, cancellationToken);
        return NoContent();
    }

    [HttpPost("{studyMaterialId:guid}/generate/estimate")]
    [ProducesResponseType(typeof(QuizGenerationEstimateDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Estimate(
        Guid studyMaterialId,
        [FromBody] QuizGenerationParametersDto request,
        CancellationToken cancellationToken)
    {
        var estimate = await quizGenerationService.EstimateAsync(
            GetUserId(),
            studyMaterialId,
            request,
            cancellationToken);
        return Ok(estimate);
    }

    [HttpPost("{studyMaterialId:guid}/generate")]
    [ProducesResponseType(typeof(StartQuizGenerationResultDto), StatusCodes.Status202Accepted)]
    public async Task<IActionResult> Generate(
        Guid studyMaterialId,
        [FromBody] QuizGenerationParametersDto request,
        CancellationToken cancellationToken)
    {
        var result = await quizGenerationService.StartGenerationAsync(
            GetUserId(),
            studyMaterialId,
            request,
            cancellationToken);
        return Accepted(result);
    }
}
