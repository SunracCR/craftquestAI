using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface IAssignmentService
{
    Task<AssignmentSummaryDto> CreateAsync(
        Guid teacherUserId,
        Guid classId,
        CreateAssignmentRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AssignmentSummaryDto>> ListByClassAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task<AssignmentDetailDto> GetDetailAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);

    Task<AssignmentCompletionDto> GetCompletionAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);

    Task CloseAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);

    Task ArchiveAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);

    Task<AssignmentDetailDto> UpdateAsync(
        Guid teacherUserId,
        Guid assignmentId,
        UpdateAssignmentRequest request,
        CancellationToken cancellationToken = default);

    Task<AssignmentAnalyticsDto> GetAssignmentAnalyticsAsync(
        Guid teacherUserId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);
}
