using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Student;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/student")]
public class StudentController(IStudentService studentService) : ApiControllerBase
{
    [HttpGet("classes")]
    [ProducesResponseType(typeof(IReadOnlyList<StudentClassSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListMyClasses(CancellationToken cancellationToken)
    {
        var classes = await studentService.ListMyClassesAsync(GetUserId(), cancellationToken);
        return Ok(classes);
    }

    [HttpGet("assignments")]
    [ProducesResponseType(typeof(IReadOnlyList<StudentAssignmentDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListMyAssignments(CancellationToken cancellationToken)
    {
        var assignments = await studentService.ListMyAssignmentsAsync(GetUserId(), cancellationToken);
        return Ok(assignments);
    }

    [HttpGet("assignments/{assignmentId:guid}/my-attempts")]
    [ProducesResponseType(typeof(IReadOnlyList<StudentAssignmentAttemptSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListMyAssignmentAttempts(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var attempts = await studentService.ListMyAssignmentAttemptsAsync(
            GetUserId(),
            assignmentId,
            cancellationToken);
        return Ok(attempts);
    }

    [HttpGet("assignments/{assignmentId:guid}/my-summary")]
    [ProducesResponseType(typeof(StudentAssignmentSummaryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyAssignmentSummary(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var summary = await studentService.GetMyAssignmentSummaryAsync(
            GetUserId(),
            assignmentId,
            cancellationToken);
        return Ok(summary);
    }
}
