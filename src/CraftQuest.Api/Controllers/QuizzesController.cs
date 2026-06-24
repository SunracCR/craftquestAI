using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Quizzes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/quizzes")]
[Authorize]
public class QuizzesController(
    IQuizService quizService,
    IQuizPdfExportService pdfExportService) : ApiControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(QuizDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(
        [FromBody] CreateQuizRequest request,
        CancellationToken cancellationToken)
    {
        var quiz = await quizService.CreateQuizAsync(GetUserId(), request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { quizId = quiz.QuizId }, quiz);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<QuizDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
    {
        var quizzes = await quizService.GetMyQuizzesAsync(GetUserId(), cancellationToken);
        return Ok(quizzes);
    }

    [HttpGet("{quizId:guid}")]
    [ProducesResponseType(typeof(QuizDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(Guid quizId, CancellationToken cancellationToken)
    {
        var quiz = await quizService.GetQuizAsync(GetUserId(), quizId, cancellationToken);
        return Ok(quiz);
    }

    [HttpPatch("{quizId:guid}")]
    [ProducesResponseType(typeof(QuizDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(
        Guid quizId,
        [FromBody] UpdateQuizRequest request,
        CancellationToken cancellationToken)
    {
        var quiz = await quizService.UpdateQuizAsync(GetUserId(), quizId, request, cancellationToken);
        return Ok(quiz);
    }

    [HttpDelete("{quizId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid quizId, CancellationToken cancellationToken)
    {
        await quizService.DeleteQuizAsync(GetUserId(), quizId, cancellationToken);
        return NoContent();
    }

    [HttpPost("{quizId:guid}/questions")]
    [ProducesResponseType(typeof(QuestionDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateQuestion(
        Guid quizId,
        [FromBody] CreateQuestionRequest request,
        CancellationToken cancellationToken)
    {
        var question = await quizService.CreateQuestionAsync(
            GetUserId(),
            quizId,
            request,
            cancellationToken);

        return CreatedAtAction(nameof(GetQuestions), new { quizId }, question);
    }

    [HttpPut("{quizId:guid}/questions/{questionId:guid}")]
    [ProducesResponseType(typeof(QuestionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateQuestion(
        Guid quizId,
        Guid questionId,
        [FromBody] CreateQuestionRequest request,
        CancellationToken cancellationToken)
    {
        var question = await quizService.UpdateQuestionAsync(
            GetUserId(),
            quizId,
            questionId,
            request,
            cancellationToken);

        return Ok(question);
    }

    [HttpDelete("{quizId:guid}/questions/{questionId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteQuestion(
        Guid quizId,
        Guid questionId,
        CancellationToken cancellationToken)
    {
        await quizService.DeleteQuestionAsync(
            GetUserId(),
            quizId,
            questionId,
            cancellationToken);

        return NoContent();
    }

    [HttpGet("{quizId:guid}/questions")]
    [ProducesResponseType(typeof(IReadOnlyList<QuestionDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetQuestions(Guid quizId, CancellationToken cancellationToken)
    {
        var questions = await quizService.GetQuestionsForAuthorAsync(
            GetUserId(),
            quizId,
            cancellationToken);

        return Ok(questions);
    }

    [HttpGet("{quizId:guid}/export/pdf")]
    [Produces("application/pdf")]
    public async Task<IActionResult> ExportPdf(
        Guid quizId,
        [FromQuery] string? language,
        CancellationToken cancellationToken)
    {
        var (bytes, fileName) = await pdfExportService.GenerateQuizPdfAsync(
            GetUserId(),
            quizId,
            language,
            cancellationToken);

        return File(bytes, "application/pdf", fileName);
    }

}
