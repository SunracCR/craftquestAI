using CraftQuest.Application.Models.StudyMaterials;

namespace CraftQuest.Application.Contracts;

public interface IStudyMaterialService
{
    Task<StudyMaterialUploadResultDto> UploadAsync(
        Guid userId,
        Stream fileStream,
        string fileName,
        string contentType,
        long fileSize,
        string? title,
        CancellationToken cancellationToken = default);

    Task<StudyMaterialDetailDto> UpdateExtractedTextAsync(
        Guid userId,
        Guid studyMaterialId,
        UpdateStudyMaterialExtractedTextRequest request,
        CancellationToken cancellationToken = default);

    Task ProcessExpiredMaterialsAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StudyMaterialSummaryDto>> ListAsync(
        Guid userId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<StudyMaterialDetailDto> GetAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken = default);

    Task<StudyMaterialDetailDto> UpdateSelectionAsync(
        Guid userId,
        Guid studyMaterialId,
        UpdateStudyMaterialSelectionRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken = default);

    Task ProcessPendingExtractionsAsync(CancellationToken cancellationToken = default);
}
