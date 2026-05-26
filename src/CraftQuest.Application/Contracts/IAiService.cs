using CraftQuest.Application.Models.Ai;

namespace CraftQuest.Application.Contracts;

public interface IAiService
{
    Task<AiNormalizeRawTextResponse> NormalizeRawTextAsync(
        Guid userId,
        AiNormalizeRawTextRequest request,
        CancellationToken cancellationToken = default);

    Task<AiJobDto> NormalizeImportBatchAsync(
        Guid userId,
        Guid importId,
        AiNormalizeImportRequest request,
        CancellationToken cancellationToken = default);

    Task<AiJobDto> GetJobAsync(
        Guid userId,
        Guid aiJobId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AiJobSummaryDto>> ListJobsAsync(
        Guid userId,
        string filter,
        CancellationToken cancellationToken = default);

    Task<int> ClearInboxHistoryAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
