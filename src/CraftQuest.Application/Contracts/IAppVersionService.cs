using CraftQuest.Application.Models.AppVersion;

namespace CraftQuest.Application.Contracts;

public interface IAppVersionService
{
    /// <summary>Devuelve el requisito de versión para <paramref name="platform"/>, o null si no hay configuración.</summary>
    Task<AppVersionRequirementDto?> GetRequirementAsync(string platform, CancellationToken cancellationToken = default);

    Task<AppVersionRequirementDto> UpsertRequirementAsync(
        string platform,
        UpsertAppVersionRequirementDto request,
        CancellationToken cancellationToken = default);
}
