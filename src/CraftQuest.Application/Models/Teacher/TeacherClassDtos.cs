namespace CraftQuest.Application.Models.Teacher;

public sealed class TeacherClassSummaryDto
{
    public required Guid ClassId { get; init; }
    public required string Name { get; init; }
    public required string? Description { get; init; }
    public required string Status { get; init; }
    public required int ActiveMemberCount { get; init; }
    public required int PendingMemberCount { get; init; }
    public required int AssignmentCount { get; init; }
}

public sealed class ClassDetailDto
{
    public required Guid ClassId { get; init; }
    public required string Name { get; init; }
    public required string? Description { get; init; }
    public required string Status { get; init; }
    public required int ActiveMemberCount { get; init; }
    public required int PendingMemberCount { get; init; }
    public required IReadOnlyList<ClassMemberDto> Members { get; init; }
    public required IReadOnlyList<AssignmentSummaryDto> Assignments { get; init; }
}

public sealed class ClassMemberDto
{
    public required Guid UserId { get; init; }
    public required string DisplayName { get; init; }
    public required string Email { get; init; }
    public required string MemberRole { get; init; }
    public required string Status { get; init; }
    public required DateTime JoinedAt { get; init; }
    public string? AvatarId { get; init; }
}

public sealed class CreateClassRequest
{
    public required string Name { get; init; }
    public string? Description { get; init; }
}

public sealed class UpdateClassRequest
{
    public required string Name { get; init; }
    public string? Description { get; init; }
}

public sealed class AddMemberRequest
{
    public required string Email { get; init; }
}

public sealed class UpdateMemberStatusRequest
{
    /// <summary>active | removed</summary>
    public required string Status { get; init; }
}
