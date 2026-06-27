using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Analytics;
using CraftQuest.Application.Models.Teacher;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/teacher")]
public class TeacherController(
    ITeacherReviewService teacherReviewService,
    IAnalyticsService analyticsService,
    IClassService classService,
    IAssignmentService assignmentService,
    ITeacherDashboardService dashboardService) : ApiControllerBase
{
    // ─── Dashboard ────────────────────────────────────────────────────────────

    [HttpGet("dashboard")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(TeacherDashboardDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken)
    {
        var dto = await dashboardService.GetDashboardAsync(GetUserId(), cancellationToken);
        return Ok(dto);
    }

    [HttpGet("activity-feed")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(IReadOnlyList<ActivityFeedItemDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActivityFeed(
        [FromQuery] int take = 30,
        CancellationToken cancellationToken = default)
    {
        var items = await dashboardService.GetActivityFeedAsync(GetUserId(), take, cancellationToken);
        return Ok(items);
    }

    // ─── Classes ──────────────────────────────────────────────────────────────

    [HttpGet("classes")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(IReadOnlyList<TeacherClassSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListClasses(
        [FromQuery] string? status = "active",
        CancellationToken cancellationToken = default)
    {
        var classes = await classService.ListTeacherClassesAsync(GetUserId(), status, cancellationToken);
        return Ok(classes);
    }

    [HttpPost("classes")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(TeacherClassSummaryDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateClass(
        [FromBody] CreateClassRequest request,
        CancellationToken cancellationToken)
    {
        var dto = await classService.CreateAsync(GetUserId(), request, cancellationToken);
        return CreatedAtAction(nameof(GetClassDetail), new { classId = dto.ClassId }, dto);
    }

    [HttpGet("classes/{classId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(ClassDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetClassDetail(
        Guid classId,
        CancellationToken cancellationToken)
    {
        var dto = await classService.GetDetailAsync(GetUserId(), classId, cancellationToken);
        return Ok(dto);
    }

    [HttpPatch("classes/{classId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateClass(
        Guid classId,
        [FromBody] UpdateClassRequest request,
        CancellationToken cancellationToken)
    {
        await classService.UpdateAsync(GetUserId(), classId, request, cancellationToken);
        return NoContent();
    }

    [HttpPost("classes/{classId:guid}/archive")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ArchiveClass(
        Guid classId,
        CancellationToken cancellationToken)
    {
        await classService.ArchiveAsync(GetUserId(), classId, cancellationToken);
        return NoContent();
    }

    [HttpPost("classes/{classId:guid}/restore")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RestoreClass(
        Guid classId,
        CancellationToken cancellationToken)
    {
        await classService.RestoreAsync(GetUserId(), classId, cancellationToken);
        return NoContent();
    }

    [HttpDelete("classes/{classId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteClass(
        Guid classId,
        CancellationToken cancellationToken)
    {
        await classService.DeleteAsync(GetUserId(), classId, cancellationToken);
        return NoContent();
    }

    // ─── Members ─────────────────────────────────────────────────────────────

    [HttpPost("classes/{classId:guid}/members")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(ClassMemberDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> AddMember(
        Guid classId,
        [FromBody] AddMemberRequest request,
        CancellationToken cancellationToken)
    {
        var member = await classService.AddMemberByEmailAsync(
            GetUserId(),
            classId,
            request.Email,
            cancellationToken);
        return CreatedAtAction(nameof(GetClassDetail), new { classId }, member);
    }

    [HttpPatch("classes/{classId:guid}/members/{userId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateMemberStatus(
        Guid classId,
        Guid userId,
        [FromBody] UpdateMemberStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (request.Status == "active")
            await classService.ApproveMemberAsync(GetUserId(), classId, userId, cancellationToken);
        else if (request.Status == "removed")
            await classService.RemoveMemberAsync(GetUserId(), classId, userId, cancellationToken);
        else
            return BadRequest("Status must be 'active' or 'removed'.");

        return NoContent();
    }

    [HttpDelete("classes/{classId:guid}/members/{userId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RemoveMember(
        Guid classId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        await classService.RemoveMemberAsync(GetUserId(), classId, userId, cancellationToken);
        return NoContent();
    }

    // ─── Assignments ─────────────────────────────────────────────────────────

    [HttpGet("classes/{classId:guid}/assignments")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(IReadOnlyList<AssignmentSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListAssignments(
        Guid classId,
        CancellationToken cancellationToken)
    {
        var dtos = await assignmentService.ListByClassAsync(GetUserId(), classId, cancellationToken);
        return Ok(dtos);
    }

    [HttpPost("classes/{classId:guid}/assignments")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(AssignmentSummaryDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateAssignment(
        Guid classId,
        [FromBody] CreateAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        var dto = await assignmentService.CreateAsync(GetUserId(), classId, request, cancellationToken);
        return CreatedAtAction(nameof(GetAssignment), new { assignmentId = dto.AssignmentId }, dto);
    }

    [HttpGet("assignments/{assignmentId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(AssignmentDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAssignment(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var dto = await assignmentService.GetDetailAsync(GetUserId(), assignmentId, cancellationToken);
        return Ok(dto);
    }

    [HttpGet("assignments/{assignmentId:guid}/completion")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(AssignmentCompletionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAssignmentCompletion(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var dto = await assignmentService.GetCompletionAsync(GetUserId(), assignmentId, cancellationToken);
        return Ok(dto);
    }

    [HttpGet("assignments/{assignmentId:guid}/analytics")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(AssignmentAnalyticsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAssignmentAnalytics(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        var dto = await assignmentService.GetAssignmentAnalyticsAsync(
            GetUserId(),
            assignmentId,
            cancellationToken);
        return Ok(dto);
    }

    [HttpPatch("assignments/{assignmentId:guid}")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(AssignmentDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateAssignment(
        Guid assignmentId,
        [FromBody] UpdateAssignmentRequest request,
        CancellationToken cancellationToken)
    {
        var dto = await assignmentService.UpdateAsync(GetUserId(), assignmentId, request, cancellationToken);
        return Ok(dto);
    }

    [HttpPost("assignments/{assignmentId:guid}/close")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> CloseAssignment(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        await assignmentService.CloseAsync(GetUserId(), assignmentId, cancellationToken);
        return NoContent();
    }

    [HttpPost("assignments/{assignmentId:guid}/archive")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ArchiveAssignment(
        Guid assignmentId,
        CancellationToken cancellationToken)
    {
        await assignmentService.ArchiveAsync(GetUserId(), assignmentId, cancellationToken);
        return NoContent();
    }

    // ─── Analytics ───────────────────────────────────────────────────────────

    [HttpGet("classes/{classId:guid}/analytics")]
    [Authorize(Policy = "Teacher")]
    [ProducesResponseType(typeof(ClassAnalyticsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetClassAnalytics(
        Guid classId,
        CancellationToken cancellationToken)
    {
        var dto = await dashboardService.GetClassAnalyticsAsync(GetUserId(), classId, cancellationToken);
        return Ok(dto);
    }

    // ─── Quiz-level review (existing) ─────────────────────────────────────────

    [HttpGet("quizzes/{quizId:guid}/practice-attempts")]
    [ProducesResponseType(typeof(IReadOnlyList<TeacherAttemptSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListQuizAttempts(
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var attempts = await teacherReviewService.ListQuizAttemptsAsync(
            GetUserId(), quizId, cancellationToken);
        return Ok(attempts);
    }

    [HttpGet("practice-sessions/{sessionId:guid}")]
    [ProducesResponseType(typeof(TeacherPracticeReviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPracticeSessionReview(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var review = await teacherReviewService.GetPracticeSessionReviewAsync(
            GetUserId(), sessionId, cancellationToken);
        return Ok(review);
    }

    [HttpGet("quizzes/{quizId:guid}/analytics")]
    [ProducesResponseType(typeof(QuizAnalyticsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetQuizAnalytics(
        Guid quizId,
        [FromQuery] Guid? classId,
        [FromQuery] Guid? assignmentId,
        CancellationToken cancellationToken)
    {
        var analytics = await analyticsService.GetQuizAnalyticsAsync(
            GetUserId(), quizId, classId, assignmentId, cancellationToken);
        return Ok(analytics);
    }
}
