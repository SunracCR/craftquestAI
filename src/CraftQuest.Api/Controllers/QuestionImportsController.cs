using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Ai;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.Imports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Authorize]
public class QuestionImportsController(
    IQuestionImportService importService,
    IAiService aiService) : ApiControllerBase
{
    [HttpPost("api/quizzes/{quizId:guid}/question-imports/process")]
    [ProducesResponseType(typeof(QuestionImportStatusDto), StatusCodes.Status202Accepted)]
    public async Task<IActionResult> Process(
        Guid quizId,
        [FromBody] ProcessImportRequest request,
        CancellationToken cancellationToken)
    {
        var status = await importService.ProcessAsync(
            GetUserId(),
            quizId,
            request,
            cancellationToken: cancellationToken);

        return Accepted(status);
    }

    [HttpPost("api/quizzes/{quizId:guid}/question-imports/process-file")]
    [ProducesResponseType(typeof(QuestionImportStatusDto), StatusCodes.Status202Accepted)]
    [RequestSizeLimit(5_000_000)]
    public async Task<IActionResult> ProcessFile(
        Guid quizId,
        [FromForm] string sourceType,
        [FromForm] IFormFile file,
        [FromForm] bool useAiNormalization = false,
        CancellationToken cancellationToken = default)
    {
        if (file.Length == 0)
        {
            return BadRequest(new { title = "File is empty." });
        }

        var normalizedType = sourceType.Trim().ToLowerInvariant();
        await using var stream = file.OpenReadStream();

        QuestionImportStatusDto status;
        if (normalizedType == "xlsx")
        {
            status = await importService.ProcessFileAsync(
                GetUserId(),
                quizId,
                stream,
                normalizedType,
                file.FileName,
                useAiNormalization,
                cancellationToken);
        }
        else
        {
            using var reader = new StreamReader(stream);
            var rawText = await reader.ReadToEndAsync(cancellationToken);

            var request = new ProcessImportRequest
            {
                SourceType = normalizedType,
                RawText = rawText,
                UseAiNormalization = useAiNormalization,
            };

            status = await importService.ProcessAsync(
                GetUserId(),
                quizId,
                request,
                file.FileName,
                cancellationToken);
        }

        return Accepted(status);
    }

    [HttpGet("api/question-imports/excel-template")]
    [Produces("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")]
    public IActionResult DownloadExcelTemplate([FromQuery] string? language = null)
    {
        var bytes = CqifExcelTemplateBuilder.Build(language);
        return File(
            bytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "craftquest_import_template.xlsx");
    }

    [HttpGet("api/question-imports/{importId:guid}/preview")]
    [ProducesResponseType(typeof(QuestionImportPreviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Preview(Guid importId, CancellationToken cancellationToken)
    {
        var preview = await importService.GetPreviewAsync(GetUserId(), importId, cancellationToken);
        return Ok(preview);
    }

    [HttpPost("api/question-imports/{importId:guid}/confirm")]
    [ProducesResponseType(typeof(QuestionImportConfirmResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Confirm(Guid importId, CancellationToken cancellationToken)
    {
        var result = await importService.ConfirmAsync(GetUserId(), importId, cancellationToken);
        return Ok(result);
    }

    [HttpPost("api/question-imports/{importId:guid}/ai-normalize")]
    [ProducesResponseType(typeof(AiJobDto), StatusCodes.Status202Accepted)]
    public async Task<IActionResult> AiNormalize(
        Guid importId,
        [FromBody] AiNormalizeImportRequest? request,
        CancellationToken cancellationToken)
    {
        var job = await aiService.NormalizeImportBatchAsync(
            GetUserId(),
            importId,
            request ?? new AiNormalizeImportRequest(),
            cancellationToken);

        return Accepted(job);
    }
}
