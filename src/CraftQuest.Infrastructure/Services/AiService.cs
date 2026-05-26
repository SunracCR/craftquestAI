using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Ai;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class AiService(
    CraftQuestDbContext dbContext,
    ICqifNormalizationProvider normalizationProvider,
    IBillingService billingService,
    IQuestionImportService questionImportService,
    IOptions<AiOptions> options) : IAiService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false,
    };

    public async Task<AiNormalizeRawTextResponse> NormalizeRawTextAsync(
        Guid userId,
        AiNormalizeRawTextRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureAiEnabled();
        var credits = options.Value.CreditsPerNormalize;
        await billingService.EnsureHasAiCreditsAsync(userId, credits, cancellationToken);

        var rawText = request.RawText.Trim();
        if (rawText.Length == 0)
        {
            throw new AppException("rawText is required.", 400);
        }

        if (rawText.Length > options.Value.MaxInputCharacters)
        {
            throw new AppException(
                $"Input exceeds maximum length ({options.Value.MaxInputCharacters} characters).",
                400);
        }

        var job = CreateJob(userId, "normalize_cqif");
        await dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            var document = await normalizationProvider.NormalizeAsync(
                rawText,
                request.Language,
                request.DefaultQuestionType,
                cancellationToken);

            await billingService.ConsumeAiCreditsAsync(
                userId,
                credits,
                "ai_job",
                job.AiJobId,
                cancellationToken);

            CompleteJob(job, document, credits, normalizationProvider.ProviderName);
            await dbContext.SaveChangesAsync(cancellationToken);

            return new AiNormalizeRawTextResponse
            {
                Document = document,
                AiJobId = job.AiJobId,
                CreditsConsumed = credits,
            };
        }
        catch (Exception ex)
        {
            FailJob(job, ex.Message);
            await dbContext.SaveChangesAsync(cancellationToken);
            throw;
        }
    }

    public async Task<AiJobDto> NormalizeImportBatchAsync(
        Guid userId,
        Guid importId,
        AiNormalizeImportRequest request,
        CancellationToken cancellationToken = default)
    {
        EnsureAiEnabled();
        var credits = options.Value.CreditsPerNormalize;
        await billingService.EnsureHasAiCreditsAsync(userId, credits, cancellationToken);

        var batch = await dbContext.QuestionImportBatches
            .Include(b => b.Rows)
            .FirstOrDefaultAsync(b => b.QuestionImportBatchId == importId, cancellationToken)
            ?? throw new AppException("Import batch not found.", 404);

        if (batch.UploadedByUserId != userId)
        {
            throw new AppException("Import batch not found.", 404);
        }

        var sourceDocument = BuildDocumentFromBatch(batch);
        var rawText = JsonSerializer.Serialize(sourceDocument, JsonOptions);

        var job = CreateJob(userId, "normalize_cqif");
        job.QuestionImportBatchId = importId;
        job.TargetQuizId = batch.QuizId;
        await dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            var normalized = await normalizationProvider.NormalizeAsync(
                rawText,
                "es",
                "single_choice",
                cancellationToken);

            await billingService.ConsumeAiCreditsAsync(
                userId,
                credits,
                "ai_job",
                job.AiJobId,
                cancellationToken);

            await questionImportService.ApplyCqifDocumentAsync(
                userId,
                importId,
                normalized,
                cancellationToken);

            CompleteJob(job, normalized, credits, normalizationProvider.ProviderName);
            await dbContext.SaveChangesAsync(cancellationToken);

            return AiJobMapper.ToDto(job, normalized, studyMaterialTitle: null);
        }
        catch (Exception ex)
        {
            FailJob(job, ex.Message);
            await dbContext.SaveChangesAsync(cancellationToken);
            throw;
        }
    }

    public async Task<AiJobDto> GetJobAsync(
        Guid userId,
        Guid aiJobId,
        CancellationToken cancellationToken = default)
    {
        var job = await dbContext.AiJobs
            .AsNoTracking()
            .FirstOrDefaultAsync(j => j.AiJobId == aiJobId, cancellationToken)
            ?? throw new AppException("AI job not found.", 404);

        if (job.RequestedByUserId != userId)
        {
            throw new AppException("AI job not found.", 404);
        }

        CqifDocument? result = null;
        if (!string.IsNullOrWhiteSpace(job.ResultJson))
        {
            result = JsonSerializer.Deserialize<CqifDocument>(job.ResultJson, JsonOptions);
        }

        var title = await ResolveStudyMaterialTitleAsync(job.StudyMaterialId, cancellationToken);
        return AiJobMapper.ToDto(job, result, title);
    }

    public async Task<IReadOnlyList<AiJobSummaryDto>> ListJobsAsync(
        Guid userId,
        string filter,
        CancellationToken cancellationToken = default)
    {
        var normalized = string.IsNullOrWhiteSpace(filter) ? "inbox" : filter.Trim().ToLowerInvariant();
        var now = DateTime.UtcNow;
        var failedCutoff = now.AddDays(-7);
        var completedCutoff = now.AddDays(-14);

        var query = dbContext.AiJobs.AsNoTracking()
            .Where(j => j.RequestedByUserId == userId && j.JobType == "generate_quiz");

        query = normalized switch
        {
            "active" => query.Where(j =>
                j.Status == "pending"
                || j.Status == "processing"
                || j.Status == "pending_retry"),
            _ => query.Where(j =>
                j.Status == "pending"
                || j.Status == "processing"
                || j.Status == "pending_retry"
                || (j.Status == "failed" && j.CreatedAt >= failedCutoff)
                || (j.Status == "completed"
                    && j.CompletedAt != null
                    && j.CompletedAt >= completedCutoff
                    && j.QuestionImportBatchId != null)),
        };

        var jobs = await query
            .OrderByDescending(j => j.CreatedAt)
            .Take(30)
            .ToListAsync(cancellationToken);

        if (jobs.Count == 0)
        {
            return [];
        }

        var materialIds = jobs
            .Where(j => j.StudyMaterialId.HasValue)
            .Select(j => j.StudyMaterialId!.Value)
            .Distinct()
            .ToList();

        var titles = await dbContext.StudyMaterials.AsNoTracking()
            .Where(m => materialIds.Contains(m.StudyMaterialId))
            .Select(m => new { m.StudyMaterialId, Title = m.Title ?? m.OriginalFileName ?? "Material" })
            .ToDictionaryAsync(m => m.StudyMaterialId, m => m.Title, cancellationToken);

        var importIds = jobs
            .Where(j => j.QuestionImportBatchId.HasValue)
            .Select(j => j.QuestionImportBatchId!.Value)
            .Distinct()
            .ToList();

        var readyImports = importIds.Count == 0
            ? new HashSet<Guid>()
            : (await dbContext.QuestionImportBatches.AsNoTracking()
                .Where(b => importIds.Contains(b.QuestionImportBatchId) && b.Status == "ready_for_review")
                .Select(b => b.QuestionImportBatchId)
                .ToListAsync(cancellationToken))
                .ToHashSet();

        return jobs
            .Select(j => AiJobMapper.ToSummary(
                j,
                j.StudyMaterialId is Guid mid && titles.TryGetValue(mid, out var title) ? title : null,
                j.QuestionImportBatchId is Guid importId && readyImports.Contains(importId)))
            .ToList();
    }

    public async Task<int> ClearInboxHistoryAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var readyImportIds = await (
            from j in dbContext.AiJobs
            join b in dbContext.QuestionImportBatches
                on j.QuestionImportBatchId equals b.QuestionImportBatchId
            where j.RequestedByUserId == userId
                && j.JobType == "generate_quiz"
                && j.Status == "completed"
                && j.QuestionImportBatchId != null
                && b.Status == "ready_for_review"
            select j.AiJobId)
            .ToListAsync(cancellationToken);

        var toRemove = await dbContext.AiJobs
            .Where(j => j.RequestedByUserId == userId
                && j.JobType == "generate_quiz"
                && (j.Status == "failed"
                    || (j.Status == "completed" && !readyImportIds.Contains(j.AiJobId))))
            .ToListAsync(cancellationToken);

        if (toRemove.Count == 0)
        {
            return 0;
        }

        dbContext.AiJobs.RemoveRange(toRemove);
        await dbContext.SaveChangesAsync(cancellationToken);
        return toRemove.Count;
    }

    private async Task<string?> ResolveStudyMaterialTitleAsync(
        Guid? studyMaterialId,
        CancellationToken cancellationToken)
    {
        if (studyMaterialId is null)
        {
            return null;
        }

        return await dbContext.StudyMaterials.AsNoTracking()
            .Where(m => m.StudyMaterialId == studyMaterialId.Value)
            .Select(m => m.Title ?? m.OriginalFileName ?? "Material")
            .FirstOrDefaultAsync(cancellationToken);
    }

    private void EnsureAiEnabled()
    {
        if (!options.Value.Enabled)
        {
            throw new AppException("AI features are disabled.", 503);
        }
    }

    private AiJob CreateJob(Guid userId, string jobType)
    {
        var job = new AiJob
        {
            AiJobId = Guid.NewGuid(),
            RequestedByUserId = userId,
            JobType = jobType,
            Status = "processing",
            ModelName = normalizationProvider.ProviderName,
            PromptVersion = options.Value.PromptVersion,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.AiJobs.Add(job);
        return job;
    }

    private void CompleteJob(AiJob job, CqifDocument document, int credits, string modelName)
    {
        job.Status = "completed";
        job.ModelName = modelName;
        job.CreditsConsumed = credits;
        job.ResultJson = JsonSerializer.Serialize(document, JsonOptions);
        job.CompletedAt = DateTime.UtcNow;
    }

    private static void FailJob(AiJob job, string message)
    {
        job.Status = "failed";
        job.ErrorMessage = message.Length > 2000 ? message[..2000] : message;
        job.CompletedAt = DateTime.UtcNow;
    }

    private static CqifDocument BuildDocumentFromBatch(QuestionImportBatch batch)
    {
        var questions = batch.Rows
            .OrderBy(r => r.RowNumber)
            .Select(r => JsonSerializer.Deserialize<CqifQuestion>(r.CqifQuestionJson!, JsonOptions))
            .Where(q => q is not null)
            .Cast<CqifQuestion>()
            .ToList();

        return new CqifDocument
        {
            CqifVersion = batch.CqifVersion,
            Quiz = new CqifQuizMetadata { Title = "Import batch" },
            Questions = questions,
        };
    }

}
