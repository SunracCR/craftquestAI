using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface IClassService
{
    Task<IReadOnlyList<TeacherClassSummaryDto>> ListTeacherClassesAsync(
        Guid teacherUserId,
        string? status = "active",
        CancellationToken cancellationToken = default);

    Task<TeacherClassSummaryDto> CreateAsync(
        Guid teacherUserId,
        CreateClassRequest request,
        CancellationToken cancellationToken = default);

    Task UpdateAsync(
        Guid teacherUserId,
        Guid classId,
        UpdateClassRequest request,
        CancellationToken cancellationToken = default);

    Task ArchiveAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task RestoreAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task<ClassDetailDto> GetDetailAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task AddMemberByEmailAsync(
        Guid teacherUserId,
        Guid classId,
        string email,
        CancellationToken cancellationToken = default);

    Task ApproveMemberAsync(
        Guid teacherUserId,
        Guid classId,
        Guid userId,
        CancellationToken cancellationToken = default);

    Task RemoveMemberAsync(
        Guid teacherUserId,
        Guid classId,
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<bool> IsActiveClassMemberAsync(
        Guid userId,
        Guid classId,
        CancellationToken cancellationToken = default);

    Task EnsureTeacherOwnsClassAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);
}
