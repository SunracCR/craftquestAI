namespace CraftQuest.Application.Contracts;

public interface IQuizPdfExportService
{
    Task<(byte[] Bytes, string FileName)> GenerateQuizPdfAsync(
        Guid userId,
        Guid quizId,
        string? languageCode,
        CancellationToken cancellationToken = default);
}
