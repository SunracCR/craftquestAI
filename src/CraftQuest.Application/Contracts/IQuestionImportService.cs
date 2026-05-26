using CraftQuest.Application.Models.Imports;

namespace CraftQuest.Application.Contracts;

public interface IQuestionImportService
{
    Task<QuestionImportStatusDto> ProcessAsync(
        Guid userId,
        Guid quizId,
        ProcessImportRequest request,
        string? originalFileName = null,
        CancellationToken cancellationToken = default);

    Task<QuestionImportStatusDto> ProcessFileAsync(
        Guid userId,
        Guid quizId,
        Stream fileStream,
        string sourceType,
        string? originalFileName,
        bool useAiNormalization = false,
        CancellationToken cancellationToken = default);

    Task<QuestionImportPreviewDto> GetPreviewAsync(
        Guid userId,
        Guid importId,
        CancellationToken cancellationToken = default);

    Task<QuestionImportConfirmResultDto> ConfirmAsync(
        Guid userId,
        Guid importId,
        CancellationToken cancellationToken = default);

    Task<QuestionImportStatusDto> ApplyCqifDocumentAsync(
        Guid userId,
        Guid importId,
        CqifDocument document,
        CancellationToken cancellationToken = default);

    Task<QuestionImportStatusDto> CreateBatchFromDocumentAsync(
        Guid userId,
        Guid quizId,
        CqifDocument document,
        string sourceType,
        string? originalFileName,
        CancellationToken cancellationToken = default);
}
