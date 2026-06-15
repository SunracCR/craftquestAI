using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.StudyMaterials;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Application.Services.StudyMaterials;
using CraftQuest.Infrastructure.StudyMaterials;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class StudyMaterialService(
    CraftQuestDbContext dbContext,
    IServiceProvider serviceProvider,
    IOptions<AiGenerationOptions> generationOptions,
    IOptions<MediaOptions> mediaOptions,
    ILogger<StudyMaterialService> logger) : IStudyMaterialService
{
    private static readonly Dictionary<string, string> ExtensionToFileType = new(StringComparer.OrdinalIgnoreCase)
    {
        [".pdf"] = "pdf",
        [".docx"] = "docx",
    };

    public async Task<StudyMaterialUploadResultDto> UploadAsync(
        Guid userId,
        Stream fileStream,
        string fileName,
        string contentType,
        long fileSize,
        string? title,
        CancellationToken cancellationToken = default)
    {
        var options = generationOptions.Value;
        if (fileSize <= 0)
        {
            throw new AppException("File is empty.", 400);
        }

        if (fileSize > options.MaxUploadBytes)
        {
            throw new AppException(
                "File exceeds maximum allowed size.",
                400,
                "MATERIAL_TOO_LARGE");
        }

        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        if (!ExtensionToFileType.TryGetValue(extension, out var fileType))
        {
            throw new AppException("Unsupported file type. Use PDF or DOCX with selectable text.", 400);
        }

        try
        {
            await using var buffer = new MemoryStream();
            await fileStream.CopyToAsync(buffer, cancellationToken);
            buffer.Position = 0;

            await ValidateSelectableTextAsync(buffer, fileType, cancellationToken);

            var materialId = Guid.NewGuid();
            var blobPath = $"study-materials/{userId:N}/{materialId:N}/original{extension}";
            var storage = ResolveStorageProvider();
            buffer.Position = 0;
            await storage.SaveAsync(blobPath, buffer, contentType, cancellationToken);

            var material = new StudyMaterial
            {
                StudyMaterialId = materialId,
                UploadedByUserId = userId,
                FileType = fileType,
                ProcessingStatus = "pending",
                Title = string.IsNullOrWhiteSpace(title)
                    ? Path.GetFileNameWithoutExtension(fileName)
                    : title.Trim(),
                OriginalFileName = Path.GetFileName(fileName),
                FileSizeBytes = fileSize,
                BlobPath = blobPath,
                RetentionExpiresAt = DateTime.UtcNow.AddDays(options.RetentionDays),
                CreatedAt = DateTime.UtcNow,
            };

            dbContext.StudyMaterials.Add(material);
            await dbContext.SaveChangesAsync(cancellationToken);

            return new StudyMaterialUploadResultDto
            {
                StudyMaterialId = materialId,
                ProcessingStatus = material.ProcessingStatus,
            };
        }
        catch (AppException)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw MapUploadException(ex);
        }
    }

    public async Task<StudyMaterialDetailDto> UpdateExtractedTextAsync(
        Guid userId,
        Guid studyMaterialId,
        UpdateStudyMaterialExtractedTextRequest request,
        CancellationToken cancellationToken = default)
    {
        var material = await LoadOwnedMaterialAsync(userId, studyMaterialId, cancellationToken, track: true);
        if (material.ProcessingStatus != "completed")
        {
            throw new AppException("Material is not ready.", 400);
        }

        var text = request.ExtractedText.Trim();
        if (text.Length == 0)
        {
            throw new AppException("Extracted text cannot be empty.", 400, "GENERATION_SCOPE_EMPTY");
        }

        material.EditedExtractedText = text;
        material.WordCount = StudyMaterialOutlineHelper.CountWords(text);
        material.LanguageCode = StudyMaterialLanguageResolver.DetectFromText(text);
        material.NeedsOcr = false;
        material.SelectionPageFrom = 1;
        material.SelectionPageTo = 1;
        await dbContext.SaveChangesAsync(cancellationToken);
        return MapDetail(material);
    }

    public async Task ProcessExpiredMaterialsAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var expired = await dbContext.StudyMaterials
            .Where(m => !m.IsPinned && m.RetentionExpiresAt != null && m.RetentionExpiresAt < now)
            .Take(20)
            .ToListAsync(cancellationToken);

        var storage = ResolveStorageProvider();
        foreach (var material in expired)
        {
            await DetachAiJobsFromStudyMaterialAsync(material.StudyMaterialId, cancellationToken);

            if (!string.IsNullOrWhiteSpace(material.BlobPath))
            {
                await storage.DeleteIfExistsAsync(material.BlobPath, cancellationToken);
            }

            var pagePaths = await dbContext.StudyMaterialPages
                .Where(p => p.StudyMaterialId == material.StudyMaterialId && p.ImageBlobPath != null)
                .Select(p => p.ImageBlobPath!)
                .ToListAsync(cancellationToken);

            foreach (var path in pagePaths)
            {
                await storage.DeleteIfExistsAsync(path, cancellationToken);
            }

            dbContext.StudyMaterials.Remove(material);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<StudyMaterialSummaryDto>> ListAsync(
        Guid userId,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 50);
        var summaries = await dbContext.StudyMaterials
            .AsNoTracking()
            .Where(m => m.UploadedByUserId == userId)
            .OrderByDescending(m => m.CreatedAt)
            .Skip(skip)
            .Take(take)
            .Select(m => new StudyMaterialSummaryDto
            {
                StudyMaterialId = m.StudyMaterialId,
                Title = m.Title ?? m.OriginalFileName ?? "Material",
                FileType = m.FileType,
                ProcessingStatus = m.ProcessingStatus,
                NeedsOcr = m.NeedsOcr,
                PageCount = m.PageCount,
                WordCount = m.WordCount,
                CreatedAt = m.CreatedAt,
                RetentionExpiresAt = m.RetentionExpiresAt,
            })
            .ToListAsync(cancellationToken);

        return await EnrichSummariesWithGenerationAsync(userId, summaries, cancellationToken);
    }

    private async Task<IReadOnlyList<StudyMaterialSummaryDto>> EnrichSummariesWithGenerationAsync(
        Guid userId,
        List<StudyMaterialSummaryDto> summaries,
        CancellationToken cancellationToken)
    {
        if (summaries.Count == 0)
        {
            return summaries;
        }

        var materialIds = summaries.Select(s => s.StudyMaterialId).ToList();

        var activeJobs = await dbContext.AiJobs.AsNoTracking()
            .Where(j => j.RequestedByUserId == userId
                && j.JobType == "generate_quiz"
                && j.StudyMaterialId != null
                && materialIds.Contains(j.StudyMaterialId.Value)
                && (j.Status == "pending"
                    || j.Status == "processing"
                    || j.Status == "pending_retry"))
            .OrderByDescending(j => j.CreatedAt)
            .ToListAsync(cancellationToken);

        var activeByMaterial = activeJobs
            .GroupBy(j => j.StudyMaterialId!.Value)
            .ToDictionary(g => g.Key, g => g.First());

        var reviewCandidates = await (
            from j in dbContext.AiJobs.AsNoTracking()
            join b in dbContext.QuestionImportBatches.AsNoTracking()
                on j.QuestionImportBatchId equals b.QuestionImportBatchId
            where j.RequestedByUserId == userId
                && j.JobType == "generate_quiz"
                && j.Status == "completed"
                && j.StudyMaterialId != null
                && materialIds.Contains(j.StudyMaterialId.Value)
                && b.Status == "ready_for_review"
            orderby j.CompletedAt descending
            select new
            {
                MaterialId = j.StudyMaterialId!.Value,
                j.AiJobId,
                ImportId = j.QuestionImportBatchId!.Value,
            })
            .ToListAsync(cancellationToken);

        var reviewByMaterial = reviewCandidates
            .GroupBy(x => x.MaterialId)
            .ToDictionary(g => g.Key, g => g.First());

        return summaries
            .Select(s =>
            {
                activeByMaterial.TryGetValue(s.StudyMaterialId, out var active);
                reviewByMaterial.TryGetValue(s.StudyMaterialId, out var review);
                var hasActive = active is not null;

                return new StudyMaterialSummaryDto
                {
                    StudyMaterialId = s.StudyMaterialId,
                    Title = s.Title,
                    FileType = s.FileType,
                    ProcessingStatus = s.ProcessingStatus,
                    NeedsOcr = s.NeedsOcr,
                    PageCount = s.PageCount,
                    WordCount = s.WordCount,
                    CreatedAt = s.CreatedAt,
                    RetentionExpiresAt = s.RetentionExpiresAt,
                    ActiveAiJobId = active?.AiJobId,
                    ActiveAiJobStatus = active?.Status,
                    ActiveAiJobStage = active?.Stage,
                    ActiveAiJobProgressPercent = active?.ProgressPercent,
                    PendingReviewImportId = hasActive ? null : review?.ImportId,
                    PendingReviewAiJobId = hasActive ? null : review?.AiJobId,
                };
            })
            .ToList();
    }

    public async Task<StudyMaterialDetailDto> GetAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken = default)
    {
        var material = await LoadOwnedMaterialAsync(userId, studyMaterialId, cancellationToken);
        return MapDetail(material);
    }

    public async Task<StudyMaterialDetailDto> UpdateSelectionAsync(
        Guid userId,
        Guid studyMaterialId,
        UpdateStudyMaterialSelectionRequest request,
        CancellationToken cancellationToken = default)
    {
        var material = await LoadOwnedMaterialAsync(userId, studyMaterialId, cancellationToken, track: true);

        if (material.ProcessingStatus != "completed")
        {
            throw new AppException("Material is not ready for selection.", 400);
        }

        if (request.PageFrom < 1 || request.PageTo < request.PageFrom)
        {
            throw new AppException("Invalid page range.", 400);
        }

        if (material.PageCount.HasValue && request.PageTo > material.PageCount.Value)
        {
            throw new AppException("Page range exceeds document length.", 400);
        }

        var maxPages = generationOptions.Value.MaxPagesPerGeneration;
        if (request.PageTo - request.PageFrom + 1 > maxPages)
        {
            throw new AppException(
                $"Page range exceeds maximum of {maxPages} pages per generation.",
                400,
                "GENERATION_PAGE_RANGE_TOO_LARGE",
                new Dictionary<string, object?> { ["maxPages"] = maxPages });
        }

        material.SelectionPageFrom = request.PageFrom;
        material.SelectionPageTo = request.PageTo;
        material.SelectionTopic = string.IsNullOrWhiteSpace(request.Topic)
            ? null
            : request.Topic.Trim();

        await dbContext.SaveChangesAsync(cancellationToken);
        return MapDetail(material);
    }

    public async Task DeleteAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken = default)
    {
        var material = await LoadOwnedMaterialAsync(userId, studyMaterialId, cancellationToken, track: true);

        // Jobs keep history; quiz and import batch stay intact.
        await DetachAiJobsFromStudyMaterialAsync(studyMaterialId, cancellationToken);

        var storage = ResolveStorageProvider();

        if (!string.IsNullOrWhiteSpace(material.BlobPath))
        {
            await storage.DeleteIfExistsAsync(material.BlobPath, cancellationToken);
        }

        foreach (var pagePath in material.Pages
                     .Where(p => !string.IsNullOrWhiteSpace(p.ImageBlobPath))
                     .Select(p => p.ImageBlobPath!))
        {
            await storage.DeleteIfExistsAsync(pagePath, cancellationToken);
        }

        dbContext.StudyMaterials.Remove(material);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ProcessPendingExtractionsAsync(CancellationToken cancellationToken = default)
    {
        var pendingIds = await dbContext.StudyMaterials
            .Where(m => m.ProcessingStatus == "pending")
            .OrderBy(m => m.CreatedAt)
            .Select(m => m.StudyMaterialId)
            .Take(3)
            .ToListAsync(cancellationToken);

        foreach (var id in pendingIds)
        {
            await ProcessOneExtractionAsync(id, cancellationToken);
        }
    }

    private async Task ProcessOneExtractionAsync(Guid materialId, CancellationToken cancellationToken)
    {
        var material = await dbContext.StudyMaterials
            .FirstOrDefaultAsync(m => m.StudyMaterialId == materialId, cancellationToken);

        if (material is null || material.ProcessingStatus != "pending")
        {
            return;
        }

        material.ProcessingStatus = "processing";
        await dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            if (string.IsNullOrWhiteSpace(material.BlobPath))
            {
                throw new InvalidOperationException("Blob path is missing.");
            }

            var storage = ResolveStorageProvider();
            await using var stream = await storage.OpenReadAsync(material.BlobPath, cancellationToken);
            var extractor = ResolveExtractor(material.FileType);
            var result = await extractor.ExtractAsync(stream, cancellationToken);

            if (result.Pages.Count > generationOptions.Value.MaxPagesPerMaterial)
            {
                var maxPages = generationOptions.Value.MaxPagesPerMaterial;
                throw new AppException(
                    $"Document exceeds maximum of {maxPages} pages.",
                    400,
                    "MATERIAL_PAGE_LIMIT_EXCEEDED",
                    new Dictionary<string, object?> { ["maxPages"] = maxPages });
            }

            if (StudyMaterialOutlineHelper.ShouldRejectAsUnselectable(result.Pages))
            {
                throw new AppException(
                    "Document has little or no selectable text. Use a PDF or DOCX with real text, not a scanned image.",
                    400,
                    "MATERIAL_NOT_SELECTABLE_TEXT");
            }

            await ClearAndApplyExtractionAsync(materialId, result, material, cancellationToken);
            material.ProcessingStatus = "completed";
            material.ErrorMessage = null;
        }
        catch (Exception ex)
        {
            material.ProcessingStatus = "failed";
            material.ErrorMessage = FormatProcessingErrorMessage(ex);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<StudyMaterial> LoadOwnedMaterialAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken,
        bool track = false)
    {
        var query = track
            ? dbContext.StudyMaterials.AsQueryable()
            : dbContext.StudyMaterials.AsNoTracking();

        var material = await query
            .Include(m => m.Pages)
            .Include(m => m.Sections)
            .FirstOrDefaultAsync(m => m.StudyMaterialId == studyMaterialId, cancellationToken)
            ?? throw new AppException("Study material not found.", 404);

        if (material.UploadedByUserId != userId)
        {
            throw new AppException("Study material not found.", 404);
        }

        return material;
    }

    private StudyMaterialDetailDto MapDetail(StudyMaterial material)
    {
        var pages = material.Pages
            .OrderBy(p => p.PageNumber)
            .Select(p => new StudyMaterialPageDto
            {
                PageNumber = p.PageNumber,
                PreviewText = TruncatePreview(p.ExtractedText),
                WordCount = p.WordCount,
                ExtractionQuality = p.ExtractionQuality,
            })
            .ToList();

        var wordsInDefaultSelection = EstimateWordsInRange(
            material,
            material.SelectionPageFrom ?? 1,
            material.SelectionPageTo ?? material.PageCount ?? 1);

        return new StudyMaterialDetailDto
        {
            StudyMaterialId = material.StudyMaterialId,
            Title = material.Title ?? material.OriginalFileName ?? "Material",
            FileType = material.FileType,
            ProcessingStatus = material.ProcessingStatus,
            NeedsOcr = material.NeedsOcr,
            ErrorMessage = material.ErrorMessage,
            PageCount = material.PageCount,
            WordCount = material.WordCount,
            SelectionPageFrom = material.SelectionPageFrom,
            SelectionPageTo = material.SelectionPageTo,
            SelectionTopic = material.SelectionTopic,
            GeneratedQuizId = material.GeneratedQuizId,
            Pages = pages,
            Sections = material.Sections
                .OrderBy(s => s.SortOrder)
                .Select(s => new StudyMaterialSectionDto
                {
                    Title = s.Title,
                    PageFrom = s.PageFrom,
                    PageTo = s.PageTo,
                })
                .ToList(),
            EstimatedMaxQuestions = Math.Min(
                generationOptions.Value.MaxQuestionsPerGeneration,
                Math.Max(5, wordsInDefaultSelection / 150)),
            RequiresTextReview = material.NeedsOcr && string.IsNullOrWhiteSpace(material.EditedExtractedText),
            EditedExtractedText = material.EditedExtractedText,
            LanguageCode = material.LanguageCode,
        };
    }

    internal static void ApplyGenerationLanguage(
        StudyMaterial material,
        QuizGenerationParametersDto parameters,
        int pageFrom,
        int pageTo)
    {
        var language = StudyMaterialLanguageResolver.Resolve(material, pageFrom, pageTo);
        parameters.Language = language;
        parameters.PageFrom = pageFrom;
        parameters.PageTo = pageTo;

        if (string.IsNullOrWhiteSpace(material.LanguageCode))
        {
            material.LanguageCode = language;
        }
    }

    internal static int EstimateWordsInRange(StudyMaterial material, int pageFrom, int pageTo)
    {
        if (!string.IsNullOrWhiteSpace(material.EditedExtractedText))
        {
            return StudyMaterialOutlineHelper.CountWords(material.EditedExtractedText);
        }

        return material.Pages
            .Where(p => p.PageNumber >= pageFrom && p.PageNumber <= pageTo)
            .Sum(p => p.WordCount);
    }

    internal static string BuildScopeText(StudyMaterial material, int pageFrom, int pageTo, string? topicFocus)
    {
        if (!string.IsNullOrWhiteSpace(material.EditedExtractedText))
        {
            var body = material.EditedExtractedText.Trim();
            if (!string.IsNullOrWhiteSpace(topicFocus))
            {
                body = $"Focus topic: {topicFocus.Trim()}\n\n{body}";
            }

            return body;
        }

        var chunks = material.Pages
            .Where(p => p.PageNumber >= pageFrom && p.PageNumber <= pageTo)
            .OrderBy(p => p.PageNumber)
            .Select(p => $"--- Page {p.PageNumber} ---\n{p.ExtractedText}")
            .ToList();

        var scopeBody = string.Join("\n\n", chunks);
        if (!string.IsNullOrWhiteSpace(topicFocus))
        {
            scopeBody = $"Focus topic: {topicFocus.Trim()}\n\n{scopeBody}";
        }

        return scopeBody;
    }

    private static string? TruncatePreview(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return null;
        }

        var trimmed = text.Trim().Replace('\n', ' ');
        return trimmed.Length <= 160 ? trimmed : trimmed[..160] + "…";
    }

    private async Task ClearAndApplyExtractionAsync(
        Guid materialId,
        DocumentExtractionResult result,
        StudyMaterial material,
        CancellationToken cancellationToken)
    {
        dbContext.StudyMaterialPages.RemoveRange(
            await dbContext.StudyMaterialPages
                .Where(p => p.StudyMaterialId == materialId)
                .ToListAsync(cancellationToken));
        dbContext.StudyMaterialSections.RemoveRange(
            await dbContext.StudyMaterialSections
                .Where(s => s.StudyMaterialId == materialId)
                .ToListAsync(cancellationToken));

        foreach (var page in result.Pages)
        {
            dbContext.StudyMaterialPages.Add(new StudyMaterialPage
            {
                StudyMaterialPageId = Guid.NewGuid(),
                StudyMaterialId = materialId,
                PageNumber = page.PageNumber,
                ExtractedText = page.Text,
                WordCount = page.WordCount,
                HasEmbeddedImages = page.HasEmbeddedImages,
                ExtractionQuality = page.ExtractionQuality,
            });
        }

        foreach (var section in result.Sections)
        {
            dbContext.StudyMaterialSections.Add(new StudyMaterialSection
            {
                StudyMaterialSectionId = Guid.NewGuid(),
                StudyMaterialId = materialId,
                Title = section.Title,
                PageFrom = section.PageFrom,
                PageTo = section.PageTo,
                SortOrder = section.SortOrder,
            });
        }

        material.PageCount = result.Pages.Count;
        material.WordCount = result.Pages.Sum(p => p.WordCount);
        material.NeedsOcr = result.NeedsOcr;
        material.OriginalText = string.Join(
            "\n\n",
            result.Pages.Select(p => p.Text).Where(t => !string.IsNullOrWhiteSpace(t)));
        material.LanguageCode = StudyMaterialLanguageResolver.DetectFromText(material.OriginalText);

        if (material.SelectionPageFrom is null && result.Pages.Count > 0)
        {
            material.SelectionPageFrom = 1;
            material.SelectionPageTo = Math.Min(
                result.Pages.Count,
                generationOptions.Value.MaxPagesPerGeneration);
        }
    }

    private async Task ValidateSelectableTextAsync(
        Stream content,
        string fileType,
        CancellationToken cancellationToken)
    {
        var options = generationOptions.Value;
        DocumentExtractionResult result;
        try
        {
            var extractor = ResolveExtractor(fileType);
            result = await extractor.ExtractAsync(content, cancellationToken);
        }
        catch (AppException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Study material text extraction failed during upload validation.");
            throw new AppException(
                "Could not read the document. Use a valid PDF or DOCX with selectable text.",
                400,
                "MATERIAL_INVALID_FILE");
        }

        if (result.Pages.Count > options.MaxPagesPerMaterial)
        {
            throw new AppException(
                $"Document exceeds maximum of {options.MaxPagesPerMaterial} pages.",
                400,
                "MATERIAL_PAGE_LIMIT_EXCEEDED",
                new Dictionary<string, object?> { ["maxPages"] = options.MaxPagesPerMaterial });
        }

        if (StudyMaterialOutlineHelper.ShouldRejectAsUnselectable(result.Pages))
        {
            throw new AppException(
                "Document has little or no selectable text. Use a PDF or DOCX with real text, not a scanned image.",
                400,
                "MATERIAL_NOT_SELECTABLE_TEXT");
        }
    }

    private IPageTextExtractor ResolveExtractor(string fileType)
    {
        var extractors = serviceProvider.GetServices<IPageTextExtractor>();
        return extractors.FirstOrDefault(e => e.FileType == fileType)
            ?? throw new AppException($"No extractor for file type '{fileType}'.", 501);
    }

    /// <summary>
    /// Desvincula trabajos de IA antes de borrar el material (la FK en SQL no tiene SET NULL).
    /// </summary>
    private Task DetachAiJobsFromStudyMaterialAsync(
        Guid studyMaterialId,
        CancellationToken cancellationToken) =>
        dbContext.AiJobs
            .Where(j => j.StudyMaterialId == studyMaterialId)
            .ExecuteUpdateAsync(
                s => s.SetProperty(j => j.StudyMaterialId, (Guid?)null),
                cancellationToken);

    private IMediaStorageProvider ResolveStorageProvider()
    {
        var providerCode = mediaOptions.Value.StorageProvider.Trim().ToLowerInvariant();
        return providerCode switch
        {
            "azure" => serviceProvider.GetRequiredService<Media.AzureBlobMediaStorageProvider>(),
            _ => serviceProvider.GetRequiredService<Media.LocalMediaStorageProvider>(),
        };
    }

    private AppException MapUploadException(Exception ex)
    {
        logger.LogError(ex, "Study material upload failed.");

        if (ex is InvalidOperationException invalidOp
            && invalidOp.Message.Contains("ConnectionString", StringComparison.OrdinalIgnoreCase))
        {
            return new AppException(
                "Media storage is not configured.",
                503,
                "STORAGE_NOT_CONFIGURED");
        }

        if (ex is DbUpdateException dbUpdate)
        {
            var sqlMessage = dbUpdate.InnerException?.Message ?? dbUpdate.Message;
            if (sqlMessage.Contains("Invalid column name", StringComparison.OrdinalIgnoreCase))
            {
                return new AppException(
                    "Study materials database schema is outdated. Apply AlterStudyMaterials_AI_Generation.sql.",
                    503,
                    "DATABASE_SCHEMA_OUTDATED");
            }

            return new AppException(
                "Could not save study material metadata.",
                500,
                "DATABASE_ERROR");
        }

        var typeName = ex.GetType().FullName ?? ex.GetType().Name;
        if (typeName.Contains("Azure.RequestFailedException", StringComparison.Ordinal)
            || typeName.Contains("StorageException", StringComparison.Ordinal))
        {
            return new AppException(
                "Could not save the file to storage.",
                503,
                "STORAGE_UPLOAD_FAILED");
        }

        if (typeName.Contains("PdfDocument", StringComparison.Ordinal)
            || typeName.Contains("OpenXml", StringComparison.Ordinal))
        {
            return new AppException(
                "Could not read the document. Use a valid PDF or DOCX with selectable text.",
                400,
                "MATERIAL_INVALID_FILE");
        }

        return new AppException(
            "Could not upload study material.",
            500,
            "MATERIAL_UPLOAD_FAILED");
    }

    private static string FormatProcessingErrorMessage(Exception ex)
    {
        if (ex is AppException app && !string.IsNullOrWhiteSpace(app.ErrorCode))
        {
            if (app.Metadata.TryGetValue("maxPages", out var maxPages) && maxPages is not null)
            {
                return $"{app.ErrorCode}|{maxPages}";
            }

            return app.ErrorCode;
        }

        var message = ex.Message;
        return message.Length > 2000 ? message[..2000] : message;
    }
}
