namespace CraftQuest.Application.Contracts;

public interface IMediaAccessService
{
    Task EnsureCanReadAsync(
        Guid mediaAssetId,
        Guid? userId,
        Guid? guestVisitId,
        string? guestToken,
        CancellationToken cancellationToken = default);
}
