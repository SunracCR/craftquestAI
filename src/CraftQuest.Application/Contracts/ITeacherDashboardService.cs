using CraftQuest.Application.Models.Teacher;

namespace CraftQuest.Application.Contracts;

public interface ITeacherDashboardService
{
    Task<TeacherDashboardDto> GetDashboardAsync(
        Guid teacherUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ActivityFeedItemDto>> GetActivityFeedAsync(
        Guid teacherUserId,
        int take = 30,
        CancellationToken cancellationToken = default);

    Task<ClassAnalyticsDto> GetClassAnalyticsAsync(
        Guid teacherUserId,
        Guid classId,
        CancellationToken cancellationToken = default);
}
