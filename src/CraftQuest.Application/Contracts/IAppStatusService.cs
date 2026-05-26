using CraftQuest.Application.Models;

namespace CraftQuest.Application.Contracts;

public interface IAppStatusService
{
    Task<AppStatusDto> GetStatusAsync(CancellationToken cancellationToken = default);
}