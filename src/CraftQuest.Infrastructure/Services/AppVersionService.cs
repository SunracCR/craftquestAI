using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.AppVersion;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace CraftQuest.Infrastructure.Services;

public class AppVersionService(CraftQuestDbContext dbContext, IMemoryCache memoryCache) : IAppVersionService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(1);

    public async Task<AppVersionRequirementDto?> GetRequirementAsync(
        string platform,
        CancellationToken cancellationToken = default)
    {
        var normalizedPlatform = platform.Trim().ToLowerInvariant();
        var cacheKey = CacheKey(normalizedPlatform);

        if (memoryCache.TryGetValue(cacheKey, out AppVersionRequirementDto? cached))
        {
            return cached;
        }

        var entity = await dbContext.AppVersionRequirements
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Platform == normalizedPlatform, cancellationToken);

        var dto = entity is null ? null : ToDto(entity);

        // Cachear también el "no hay requisito" para no golpear la BD en cada arranque de app.
        memoryCache.Set(cacheKey, dto, CacheDuration);
        return dto;
    }

    public async Task<AppVersionRequirementDto> UpsertRequirementAsync(
        string platform,
        UpsertAppVersionRequirementDto request,
        CancellationToken cancellationToken = default)
    {
        var normalizedPlatform = platform.Trim().ToLowerInvariant();

        var entity = await dbContext.AppVersionRequirements
            .FirstOrDefaultAsync(x => x.Platform == normalizedPlatform, cancellationToken);

        if (entity is null)
        {
            entity = new AppVersionRequirement { Platform = normalizedPlatform };
            dbContext.AppVersionRequirements.Add(entity);
        }

        entity.MinSupportedVersion = request.MinSupportedVersion.Trim();
        entity.LatestVersion = request.LatestVersion?.Trim();
        entity.UpdateUrl = request.UpdateUrl.Trim();
        entity.Message = request.Message?.Trim();
        entity.UpdatedAtUtc = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        memoryCache.Remove(CacheKey(normalizedPlatform));

        return ToDto(entity);
    }

    private static AppVersionRequirementDto ToDto(AppVersionRequirement entity) => new()
    {
        Platform = entity.Platform,
        MinSupportedVersion = entity.MinSupportedVersion,
        LatestVersion = entity.LatestVersion,
        UpdateUrl = entity.UpdateUrl,
        Message = entity.Message,
    };

    private static string CacheKey(string platform) => $"app-version:requirement:{platform}";
}
