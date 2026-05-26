using CraftQuest.Application.Models.Sharing;

namespace CraftQuest.Application.Contracts;

public interface IShareCodeService
{
    Task<ShareCodeDto?> GetQuizShareCodeAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<ShareCodeDto> CreateShareCodeAsync(
        Guid userId,
        Guid quizId,
        CreateShareCodeRequest request,
        CancellationToken cancellationToken = default);

    Task<RedeemShareCodeResultDto> RedeemAsync(
        Guid userId,
        RedeemShareCodeRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AccessibleQuizDto>> GetAccessibleQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task RemoveAccessibleQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<bool> HasQuizAccessAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<InviteUsersResultDto> InviteUsersByEmailAsync(
        Guid ownerId,
        Guid quizId,
        InviteUsersRequest request,
        CancellationToken cancellationToken = default);
}
