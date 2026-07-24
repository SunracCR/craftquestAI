namespace CraftQuest.Application.Contracts;

using CraftQuest.Application.Models.Offline;

public interface IOfflineQuizService
{
    Task<OfflineQuizPackageDto> GetOfflinePackageAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<OfflineSyncResultDto> SyncOfflineSessionAsync(
        Guid userId,
        OfflineSyncRequest request,
        CancellationToken cancellationToken = default);
}
