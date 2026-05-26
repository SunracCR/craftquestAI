using CraftQuest.Application.Models.Practice;
using CraftQuest.Application.Models.Student;

namespace CraftQuest.Application.Contracts;

public interface IStudentService
{
    Task<IReadOnlyList<StudentClassSummaryDto>> ListMyClassesAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StudentAssignmentDto>> ListMyAssignmentsAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StudentAssignmentAttemptSummaryDto>> ListMyAssignmentAttemptsAsync(
        Guid userId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);

    Task<StudentAssignmentSummaryDto> GetMyAssignmentSummaryAsync(
        Guid userId,
        Guid assignmentId,
        CancellationToken cancellationToken = default);
}
