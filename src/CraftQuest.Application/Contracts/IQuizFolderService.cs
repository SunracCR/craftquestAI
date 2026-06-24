using CraftQuest.Application.Models.Quizzes;

namespace CraftQuest.Application.Contracts;

public interface IQuizFolderService
{
    Task<IReadOnlyList<QuizFolderDto>> GetMyFoldersAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<QuizFolderDto> CreateFolderAsync(
        Guid userId,
        CreateQuizFolderRequest request,
        CancellationToken cancellationToken = default);

    Task<QuizFolderDto> UpdateFolderAsync(
        Guid userId,
        Guid folderId,
        UpdateQuizFolderRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteFolderAsync(
        Guid userId,
        Guid folderId,
        CancellationToken cancellationToken = default);
}
