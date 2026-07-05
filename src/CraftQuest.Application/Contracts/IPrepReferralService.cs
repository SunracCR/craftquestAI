using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Application.Contracts;

public interface IPrepReferralService
{
    Task<PrepReferralCodeDto> GetOrCreateReferralCodeAsync(
        Guid userId,
        Guid catalogItemId,
        CancellationToken cancellationToken = default);

    Task ApplyReferralRewardIfApplicableAsync(
        Purchase purchase,
        Guid catalogItemId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<PrepReferralLandingPreviewDto?> GetLandingPreviewAsync(
        string slug,
        CancellationToken cancellationToken = default);

    Task<(Stream Stream, string ContentType, long? FileSizeBytes)?> OpenPublishedCoverAsync(
        string slug,
        CancellationToken cancellationToken = default);

    Task<Guid?> ResolveReferralCodeIdAsync(
        string? referralCode,
        Guid catalogItemId,
        CancellationToken cancellationToken = default);
}
