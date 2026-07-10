using System.Text.Json;
using CraftQuest.Application;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Application.Models.Quizzes;
using CraftQuest.Application.Models.StudyMaterials;
using CraftQuest.Application.Options;
using CraftQuest.Application.Services.StudyMaterials;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Notifications;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Ai;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services;

public class QuizGenerationService(
    CraftQuestDbContext dbContext,
    IQuizGenerationProvider generationProvider,
    IQuestionImportService questionImportService,
    IQuizService quizService,
    IBillingService billingService,
    INotificationService notificationService,
    IOptions<AiOptions> aiOptions,
    IOptions<AiGenerationOptions> generationOptions,
    AiGenerationTraceContext trace,
    IAiGenerationJobProgress jobProgress,
    ILogger<QuizGenerationService> logger) : IQuizGenerationService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public async Task<QuizGenerationEstimateDto> EstimateAsync(
        Guid userId,
        Guid studyMaterialId,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default)
    {
        EnsureAiEnabled();
        parameters = QuizGenerationPresetApplier.Apply(parameters);
        parameters.QuestionCount = await CapQuestionCountAsync(
            parameters.QuestionCount,
            userId,
            parameters.TargetQuizId,
            cancellationToken);
        var material = await LoadReadyMaterialAsync(userId, studyMaterialId, cancellationToken);
        var (pageFrom, pageTo) = ResolvePageRange(material, parameters);
        StudyMaterialService.ApplyGenerationLanguage(material, parameters, pageFrom, pageTo);
        await dbContext.SaveChangesAsync(cancellationToken);
        var words = StudyMaterialService.EstimateWordsInRange(material, pageFrom, pageTo);
        var pageCount = material.PageCount ?? 0;
        var credits = AiOptions.CalculateGenerationCredits(
            parameters.QuestionCount,
            pageCount,
            aiOptions.Value);
        var documentSizeSurcharge = AiOptions.CalculateDocumentSizeSurcharge(pageCount, aiOptions.Value);

        var planCapacity = await ResolveImportableCountAsync(
            userId,
            parameters.TargetQuizId,
            cancellationToken);
        var materialCap = Math.Min(
            generationOptions.Value.MaxQuestionsPerGeneration,
            Math.Max(5, words / 150));
        var maxSelectable = Math.Min(planCapacity, materialCap);
        var importableForRequest = Math.Min(parameters.QuestionCount, maxSelectable);

        var available = (await billingService.GetMyBillingAsync(userId, cancellationToken))
            .Credits.AiCredits;

        return new QuizGenerationEstimateDto
        {
            CreditsRequired = credits,
            AiCreditsAvailable = available,
            EstimatedImportableQuestions = importableForRequest,
            MaxSelectableQuestions = maxSelectable,
            WordsInScope = words,
            GenerationLanguage = parameters.Language,
            DocumentSizeSurcharge = documentSizeSurcharge,
        };
    }

    public async Task<StartQuizGenerationResultDto> StartGenerationAsync(
        Guid userId,
        Guid studyMaterialId,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken = default)
    {
        EnsureAiEnabled();
        parameters = QuizGenerationPresetApplier.Apply(parameters);
        var material = await LoadReadyMaterialAsync(userId, studyMaterialId, cancellationToken);

        EnsureMaterialReadyForGeneration(material);

        await RecoverAbandonedGenerationJobsForMaterialAsync(studyMaterialId, cancellationToken);
        await RecoverAbandonedGenerationJobsAsync(cancellationToken);

        var activeJob = await dbContext.AiJobs
            .Where(j => j.StudyMaterialId == studyMaterialId
                && j.JobType == "generate_quiz"
                && (j.Status == "pending"
                    || j.Status == "processing"
                    || j.Status == "pending_retry"))
            .OrderByDescending(j => j.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (activeJob is not null)
        {
            var existingParams = string.IsNullOrWhiteSpace(activeJob.InputJson)
                ? parameters
                : JsonSerializer.Deserialize<QuizGenerationParametersDto>(activeJob.InputJson, JsonOptions)
                    ?? parameters;
            var existingCredits = AiOptions.CalculateGenerationCredits(
                existingParams.QuestionCount,
                material.PageCount ?? 0,
                aiOptions.Value);

            return new StartQuizGenerationResultDto
            {
                AiJobId = activeJob.AiJobId,
                Status = activeJob.Status,
                TargetQuizId = activeJob.TargetQuizId,
                CreditsRequired = existingCredits,
                ResumedExistingJob = true,
            };
        }

        var (pageFrom, pageTo) = ResolvePageRange(material, parameters);
        StudyMaterialService.ApplyGenerationLanguage(material, parameters, pageFrom, pageTo);
        await dbContext.SaveChangesAsync(cancellationToken);
        parameters.QuestionCount = await CapQuestionCountAsync(
            parameters.QuestionCount,
            userId,
            parameters.TargetQuizId,
            cancellationToken);

        var words = StudyMaterialService.EstimateWordsInRange(material, pageFrom, pageTo);
        if (words == 0)
        {
            throw new AppException("No text found in the selected scope.", 400, "GENERATION_SCOPE_EMPTY");
        }

        var credits = AiOptions.CalculateGenerationCredits(
            parameters.QuestionCount,
            material.PageCount ?? 0,
            aiOptions.Value);
        await billingService.EnsureHasAiCreditsAsync(userId, credits, cancellationToken);

        if (parameters.TargetQuizId is null)
        {
            await billingService.EnsureCanCreateQuizAsync(userId, cancellationToken);
        }
        else
        {
            await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);
        }

        material.SelectionPageFrom = pageFrom;
        material.SelectionPageTo = pageTo;
        material.SelectionTopic = parameters.TopicFocus;

        Guid? targetQuizId = null;
        if (parameters.TargetQuizId is Guid existingQuizId)
        {
            await EnsureQuizOwnerAsync(userId, existingQuizId, cancellationToken);
            targetQuizId = existingQuizId;
        }

        var job = new AiJob
        {
            AiJobId = Guid.NewGuid(),
            RequestedByUserId = userId,
            JobType = "generate_quiz",
            Status = "pending",
            Stage = AiJobStages.Queued,
            ProgressPercent = 0,
            StudyMaterialId = studyMaterialId,
            TargetQuizId = targetQuizId,
            ModelName = generationProvider.ProviderName,
            PromptVersion = aiOptions.Value.QuizGenerationPromptVersion,
            InputJson = JsonSerializer.Serialize(parameters, JsonOptions),
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.AiJobs.Add(job);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new StartQuizGenerationResultDto
        {
            AiJobId = job.AiJobId,
            Status = job.Status,
            TargetQuizId = targetQuizId,
            CreditsRequired = credits,
        };
    }

    public async Task<StartQuizGenerationResultDto> RetryGenerationJobAsync(
        Guid userId,
        Guid aiJobId,
        CancellationToken cancellationToken = default)
    {
        EnsureAiEnabled();

        var job = await dbContext.AiJobs.FirstOrDefaultAsync(j => j.AiJobId == aiJobId, cancellationToken)
            ?? throw new AppException("AI job not found.", 404);

        if (job.RequestedByUserId != userId || job.JobType != "generate_quiz")
        {
            throw new AppException("AI job not found.", 404);
        }

        if (job.Status != "failed")
        {
            throw new AppException(
                "Only failed generation jobs can be retried.",
                409,
                "GENERATION_JOB_NOT_RETRYABLE");
        }

        if (job.StudyMaterialId is null || job.InputJson is null)
        {
            throw new AppException("Generation job is missing required data.", 400);
        }

        var parameters = JsonSerializer.Deserialize<QuizGenerationParametersDto>(job.InputJson, JsonOptions)
            ?? throw new AppException("Invalid generation parameters.", 400);

        var pageCount = 0;
        if (job.StudyMaterialId is Guid materialId)
        {
            pageCount = await dbContext.StudyMaterials
                .AsNoTracking()
                .Where(m => m.StudyMaterialId == materialId)
                .Select(m => m.PageCount ?? 0)
                .FirstOrDefaultAsync(cancellationToken);
        }

        var credits = AiOptions.CalculateGenerationCredits(
            parameters.QuestionCount,
            pageCount,
            aiOptions.Value);
        await billingService.EnsureHasAiCreditsAsync(userId, credits, cancellationToken);

        job.Status = "pending";
        job.Stage = AiJobStages.Queued;
        job.ProgressPercent = 0;
        job.StartedAt = null;
        job.ErrorMessage = null;
        job.ErrorCode = null;
        job.NextRetryAt = null;
        job.RetryAttempt = 0;
        job.CompletedAt = null;
        job.CreditsConsumed = null;

        await dbContext.SaveChangesAsync(cancellationToken);

        return new StartQuizGenerationResultDto
        {
            AiJobId = job.AiJobId,
            Status = job.Status,
            TargetQuizId = job.TargetQuizId,
            CreditsRequired = credits,
        };
    }

    public async Task ProcessPendingGenerationJobsAsync(CancellationToken cancellationToken = default)
    {
        await RecoverAbandonedGenerationJobsAsync(cancellationToken);

        var now = DateTime.UtcNow;
        var jobIds = await dbContext.AiJobs
            .Where(j => j.JobType == "generate_quiz"
                && (j.Status == "pending"
                    || (j.Status == "pending_retry" && j.NextRetryAt != null && j.NextRetryAt <= now)))
            .OrderBy(j => j.CreatedAt)
            .Select(j => j.AiJobId)
            .Take(2)
            .ToListAsync(cancellationToken);

        foreach (var jobId in jobIds)
        {
            await ProcessOneJobAsync(jobId, cancellationToken);
        }
    }

    private async Task ProcessOneJobAsync(Guid jobId, CancellationToken cancellationToken)
    {
        var job = await dbContext.AiJobs.FirstOrDefaultAsync(j => j.AiJobId == jobId, cancellationToken);
        if (job is null || job.JobType != "generate_quiz")
        {
            return;
        }

        if (job.Status == "pending_retry")
        {
            if (job.NextRetryAt is null || job.NextRetryAt > DateTime.UtcNow)
            {
                return;
            }
        }
        else if (job.Status != "pending")
        {
            return;
        }

        job.Status = "processing";
        job.StartedAt = DateTime.UtcNow;
        job.Stage = AiJobStages.Preparing;
        job.ProgressPercent = 5;
        await dbContext.SaveChangesAsync(cancellationToken);

        trace.BeginJob(job.AiJobId);
        jobProgress.Attach(job.AiJobId);

        var timeoutMinutes = Math.Max(5, generationOptions.Value.GenerationJobTimeoutMinutes);
        using var jobTimeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        jobTimeoutCts.CancelAfter(TimeSpan.FromMinutes(timeoutMinutes));
        var jobToken = jobTimeoutCts.Token;

        try
        {
            if (job.StudyMaterialId is null || job.InputJson is null)
            {
                throw new InvalidOperationException("Generation job is missing required data.");
            }

            var parameters = JsonSerializer.Deserialize<QuizGenerationParametersDto>(job.InputJson, JsonOptions)
                ?? throw new InvalidOperationException("Invalid generation parameters.");

            parameters = QuizGenerationPresetApplier.Apply(parameters);
            parameters.QuestionCount = await CapQuestionCountAsync(
                parameters.QuestionCount,
                job.RequestedByUserId,
                job.TargetQuizId,
                cancellationToken);

            var material = await dbContext.StudyMaterials
                .AsNoTracking()
                .Include(m => m.Pages)
                .FirstAsync(m => m.StudyMaterialId == job.StudyMaterialId.Value, jobToken);

            if (material.UploadedByUserId != job.RequestedByUserId)
            {
                throw new InvalidOperationException("Material ownership mismatch.");
            }

            EnsureMaterialReadyForGeneration(material);

            var sourceText = StudyMaterialService.BuildScopeText(
                material,
                parameters.PageFrom,
                parameters.PageTo,
                parameters.TopicFocus);

            trace.Stage("job.input", "Generation parameters", new
            {
                job.StudyMaterialId,
                parameters.QuestionCount,
                parameters.Language,
                parameters.Difficulty,
                parameters.AllowedQuestionTypes,
                parameters.PageFrom,
                parameters.PageTo,
                parameters.TopicFocus,
                parameters.Preset,
                sourceChars = sourceText.Length,
            });

            await jobProgress.UpdateAsync(AiJobStages.Preparing, 8, jobToken);
            var document = await GenerateWithRetryAsync(sourceText, parameters, jobToken);

            await jobProgress.UpdateAsync(AiJobStages.Validating, 72, jobToken);
            document.CqifVersion = "2.0";
            document.Quiz ??= new Application.Models.Imports.CqifQuizMetadata
            {
                Title = material.Title ?? "Generated quiz",
            };

            trace.DocumentSnapshot("post-gemini", document);

            var beforeSanitize = document.Questions.Count;
            var typesBefore = document.Questions
                .GroupBy(q => q.Type ?? "(null)")
                .ToDictionary(g => g.Key, g => g.Count());

            CqifGenerationSanitizer.Sanitize(document, parameters.AllowedQuestionTypes);

            trace.Stage("sanitize", "Question type filter applied", new
            {
                before = beforeSanitize,
                after = document.Questions.Count,
                allowedTypes = parameters.AllowedQuestionTypes,
                typesBefore,
                typesAfter = document.Questions
                    .GroupBy(q => q.Type ?? "(null)")
                    .ToDictionary(g => g.Key, g => g.Count()),
            });

            CqifGenerationSanitizer.ValidateOrThrow(document);

            if (document.Questions.Count == 0)
            {
                throw new AppException(
                    "AI returned no questions matching the allowed types after sanitization.",
                    502,
                    "AI_GENERATION_NO_VALID_QUESTIONS");
            }

            if (document.Questions.Count > parameters.QuestionCount)
            {
                document.Questions = document.Questions.Take(parameters.QuestionCount).ToList();
            }

            var targetQuizId = job.TargetQuizId;
            if (targetQuizId is null)
            {
                var created = await quizService.CreateQuizAsync(
                    job.RequestedByUserId,
                    new CreateQuizRequest
                    {
                        Title = $"{material.Title ?? material.OriginalFileName} — IA",
                        Visibility = "private",
                    },
                    jobToken);
                targetQuizId = created.QuizId;
                job.TargetQuizId = targetQuizId;
                await dbContext.StudyMaterials
                    .Where(m => m.StudyMaterialId == material.StudyMaterialId)
                    .ExecuteUpdateAsync(
                        s => s.SetProperty(m => m.GeneratedQuizId, targetQuizId),
                        jobToken);
                trace.Stage("quiz.created", "New quiz for AI import", new { targetQuizId });
            }

            var credits = AiOptions.CalculateGenerationCredits(
                document.Questions.Count,
                material.PageCount ?? 0,
                aiOptions.Value);

            await jobProgress.UpdateAsync(AiJobStages.Importing, 88, jobToken);
            var importStatus = await questionImportService.CreateBatchFromDocumentAsync(
                job.RequestedByUserId,
                targetQuizId.Value,
                document,
                "ai",
                material.OriginalFileName,
                jobToken);

            trace.Stage("import.batch", "Import batch created from CQIF", new
            {
                importStatus.ImportId,
                importStatus.Status,
                importStatus.TotalQuestionsDetected,
                importStatus.ValidQuestions,
                importStatus.QuestionsWithErrors,
                importStatus.QuestionsWithWarnings,
            });

            if (importStatus.ValidQuestions == 0)
            {
                throw new AppException(
                    "Generated questions failed CQIF validation; none are importable.",
                    502,
                    "AI_GENERATION_IMPORT_EMPTY",
                    new Dictionary<string, object?>
                    {
                        ["importId"] = importStatus.ImportId,
                        ["totalDetected"] = importStatus.TotalQuestionsDetected,
                        ["withErrors"] = importStatus.QuestionsWithErrors,
                    });
            }

            job.Status = "completed";
            job.Stage = AiJobStages.Completed;
            job.ProgressPercent = 100;
            job.QuestionImportBatchId = importStatus.ImportId;
            job.CreditsConsumed = credits;
            job.ResultJson = JsonSerializer.Serialize(document, JsonOptions);
            job.CompletedAt = DateTime.UtcNow;
            job.ModelName = generationProvider.ProviderName;
            job.ErrorCode = null;
            job.ErrorMessage = null;
            job.NextRetryAt = null;

            await billingService.ConsumeAiCreditsAsync(
                job.RequestedByUserId,
                credits,
                "ai_job",
                job.AiJobId,
                jobToken,
                saveImmediately: false);
        }
        catch (AppException ex)
        {
            trace.Stage("job.failed", "AppException", new { ex.ErrorCode, ex.Message });
            ApplyJobFailure(job, ex);
        }
        catch (OperationCanceledException) when (jobTimeoutCts.IsCancellationRequested)
        {
            trace.Stage("job.failed", "Generation timeout", new { timeoutMinutes });
            job.Status = "failed";
            job.Stage = AiJobStages.Failed;
            job.ProgressPercent = null;
            job.ErrorCode = "GENERATION_TIMEOUT";
            job.ErrorMessage = TruncateJobError(
                $"Generation exceeded the maximum time ({timeoutMinutes} minutes). Please try again.");
            job.CompletedAt = DateTime.UtcNow;
            job.NextRetryAt = null;
        }
        catch (DbUpdateException ex)
        {
            var inner = ex.InnerException?.Message ?? ex.Message;
            trace.Stage("job.failed", "DbUpdateException", new
            {
                inner,
                entities = ex.Entries.Select(e => e.Entity.GetType().Name).Distinct().ToList(),
            });
            logger.LogError(ex, "[AiGenTrace] Job {JobId} DbUpdateException: {Inner}", job.AiJobId, inner);
            job.Status = "failed";
            job.Stage = AiJobStages.Failed;
            job.ProgressPercent = null;
            job.ErrorCode = "AI_GENERATION_SAVE_FAILED";
            job.ErrorMessage = TruncateJobError(inner);
            job.CompletedAt = DateTime.UtcNow;
            job.NextRetryAt = null;
        }
        catch (Exception ex)
        {
            trace.Stage("job.failed", "Unhandled exception", new { ex.Message, ex.GetType().Name });
            logger.LogError(ex, "[AiGenTrace] Job {JobId} failed", job.AiJobId);
            job.Status = "failed";
            job.Stage = AiJobStages.Failed;
            job.ProgressPercent = null;
            job.ErrorCode = InferErrorCode(ex.Message);
            job.ErrorMessage = TruncateJobError(ex.Message);
            job.CompletedAt = DateTime.UtcNow;
            job.NextRetryAt = null;
        }
        finally
        {
            jobProgress.Detach();
            trace.EndJob();
        }

        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            await NotifyAiJobOutcomeAsync(job, cancellationToken);
        }
        catch (Exception saveEx)
        {
            logger.LogError(
                saveEx,
                "[AiGenTrace] Job {JobId} could not persist final status {Status}",
                job.AiJobId,
                job.Status);
        }
    }

    private async Task NotifyAiJobOutcomeAsync(AiJob job, CancellationToken cancellationToken)
    {
        if (job.Status is not ("completed" or "failed"))
        {
            return;
        }

        string? quizTitle = null;
        if (job.TargetQuizId is Guid quizId)
        {
            quizTitle = await dbContext.Quizzes
                .AsNoTracking()
                .Where(q => q.QuizId == quizId)
                .Select(q => q.Title)
                .FirstOrDefaultAsync(cancellationToken);
        }

        var type = job.Status == "completed"
            ? NotificationTypes.AiJobCompleted
            : NotificationTypes.AiJobFailed;

        var payload = new NotificationPayload
        {
            AiJobId = job.AiJobId,
            QuizId = job.TargetQuizId,
            QuizTitle = quizTitle ?? "Quiz",
            Route = job.TargetQuizId is Guid id ? $"quizzes/{id}" : "ai/jobs",
        };

        await NotificationPublisher.TryNotifyAsync(
            () => notificationService.NotifyAsync(
                job.RequestedByUserId,
                type,
                payload,
                $"{type}:{job.AiJobId}",
                cancellationToken),
            logger,
            "ai_job_outcome");
    }

    private async Task RecoverAbandonedGenerationJobsForMaterialAsync(
        Guid studyMaterialId,
        CancellationToken cancellationToken)
    {
        var minutes = Math.Max(3, generationOptions.Value.StaleProcessingMinutesOnStart);
        await RecoverAbandonedGenerationJobsCoreAsync(
            studyMaterialId,
            DateTime.UtcNow.AddMinutes(-minutes),
            cancellationToken);
    }

    private async Task RecoverAbandonedGenerationJobsAsync(CancellationToken cancellationToken)
    {
        var cutoff = DateTime.UtcNow.AddMinutes(
            -Math.Max(5, generationOptions.Value.StaleProcessingMinutes));
        await RecoverAbandonedGenerationJobsCoreAsync(null, cutoff, cancellationToken);
    }

    private async Task RecoverAbandonedGenerationJobsCoreAsync(
        Guid? studyMaterialId,
        DateTime cutoff,
        CancellationToken cancellationToken)
    {

        var abandoned = await dbContext.AiJobs
            .Where(j => j.JobType == "generate_quiz"
                && j.CompletedAt == null
                && j.CreatedAt < cutoff
                && (studyMaterialId == null || j.StudyMaterialId == studyMaterialId)
                && (j.Status == "processing"
                    || j.Status == "pending"
                    || j.Status == "pending_retry"))
            .ToListAsync(cancellationToken);

        if (abandoned.Count == 0)
        {
            return;
        }

        const string message =
            "Generation was interrupted or timed out. You can start a new generation.";
        foreach (var job in abandoned)
        {
            job.Status = "failed";
            job.ErrorCode = "GENERATION_STALE_ABORTED";
            job.ErrorMessage = TruncateJobError(message);
            job.CompletedAt = DateTime.UtcNow;
            job.NextRetryAt = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<Application.Models.Imports.CqifDocument> GenerateWithRetryAsync(
        string sourceText,
        QuizGenerationParametersDto parameters,
        CancellationToken cancellationToken)
    {
        var maxAttempts = Math.Max(1, generationOptions.Value.GenerationJobMaxAttempts);
        Exception? last = null;

        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                return await generationProvider.GenerateAsync(sourceText, parameters, cancellationToken);
            }
            catch (Exception ex) when (attempt < maxAttempts && GeminiApiErrorHandler.IsRetryable(ex))
            {
                last = ex;
                await Task.Delay(GeminiApiErrorHandler.GetRetryDelay(attempt), cancellationToken);
            }
            catch (Exception ex)
            {
                last = ex;
                break;
            }
        }

        throw last ?? new InvalidOperationException("Quiz generation failed.");
    }

    private async Task<int> ResolveImportableCountAsync(
        Guid userId,
        Guid? targetQuizId,
        CancellationToken cancellationToken)
    {
        if (targetQuizId is Guid quizId)
        {
            var capacity = await billingService.GetQuizQuestionCapacityAsync(
                userId,
                quizId,
                cancellationToken);
            return capacity.RemainingSlots;
        }

        var billing = await billingService.GetMyBillingAsync(userId, cancellationToken);
        return billing.Entitlements.MaxQuestionsPerQuiz
            ?? generationOptions.Value.MaxQuestionsPerGeneration;
    }

    private static void EnsureMaterialReadyForGeneration(StudyMaterial material)
    {
        if (!string.IsNullOrWhiteSpace(material.EditedExtractedText))
        {
            return;
        }

        if (material.NeedsOcr && material.WordCount < 20)
        {
            throw new AppException(
                "Review and edit the extracted text before generating. Use a PDF or DOCX with selectable text.",
                400,
                "MATERIAL_NEEDS_OCR");
        }
    }

    private async Task<StudyMaterial> LoadReadyMaterialAsync(
        Guid userId,
        Guid studyMaterialId,
        CancellationToken cancellationToken)
    {
        var material = await dbContext.StudyMaterials
            .Include(m => m.Pages)
            .FirstOrDefaultAsync(m => m.StudyMaterialId == studyMaterialId, cancellationToken)
            ?? throw new AppException("Study material not found.", 404);

        if (material.UploadedByUserId != userId)
        {
            throw new AppException("Study material not found.", 404);
        }

        if (material.ProcessingStatus != "completed")
        {
            throw new AppException("Material is still being processed.", 400);
        }

        return material;
    }

    private static (int PageFrom, int PageTo) ResolvePageRange(
        StudyMaterial material,
        QuizGenerationParametersDto parameters)
    {
        if (!string.IsNullOrWhiteSpace(material.EditedExtractedText))
        {
            return (1, 1);
        }

        // Always use the full document; client pageFrom/pageTo are ignored.
        var pageTo = material.PageCount ?? 1;
        return (1, Math.Max(1, pageTo));
    }

    private async Task EnsureQuizOwnerAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var owns = await dbContext.Quizzes.AnyAsync(
            q => q.QuizId == quizId && q.CreatedByUserId == userId,
            cancellationToken);

        if (!owns)
        {
            throw new AppException("Quiz not found.", 404);
        }
    }

    private void EnsureAiEnabled()
    {
        if (!aiOptions.Value.Enabled)
        {
            throw new AppException("AI features are disabled.", 503);
        }

        if (string.IsNullOrWhiteSpace(aiOptions.Value.GeminiApiKey))
        {
            throw new AppException(
                "Gemini API key is not configured for quiz generation.",
                503,
                "AI_NOT_CONFIGURED");
        }
    }

    private void ApplyJobFailure(AiJob job, AppException ex)
    {
        job.ErrorCode = ex.ErrorCode ?? InferErrorCode(ex.Message);
        job.ErrorMessage = TruncateJobError(ex.Message);

        if (GeminiApiErrorHandler.IsDeferredRetryEligible(ex.ErrorCode)
            && job.RetryAttempt < generationOptions.Value.DeferredRetryMaxAttempts)
        {
            var delays = generationOptions.Value.DeferredRetryDelayMinutes;
            var delayIndex = Math.Min(job.RetryAttempt, Math.Max(0, delays.Length - 1));
            var delayMinutes = delays.Length > 0 ? delays[delayIndex] : 5;

            job.Status = "pending_retry";
            job.Stage = AiJobStages.Queued;
            job.ProgressPercent = 0;
            job.NextRetryAt = DateTime.UtcNow.AddMinutes(delayMinutes);
            job.RetryAttempt++;
            job.CompletedAt = null;
            return;
        }

        job.Status = "failed";
        job.Stage = AiJobStages.Failed;
        job.ProgressPercent = null;
        job.CompletedAt = DateTime.UtcNow;
        job.NextRetryAt = null;
    }

    private static string? InferErrorCode(string message) =>
        message.Contains("Invalid CQIF JSON", StringComparison.OrdinalIgnoreCase)
        || message.Contains("could not be converted", StringComparison.OrdinalIgnoreCase)
            ? "AI_GENERATION_INVALID_OUTPUT"
            : null;

    private static string TruncateJobError(string message) =>
        message.Length > 2000 ? message[..2000] : message;

    private async Task<int> CapQuestionCountAsync(
        int questionCount,
        Guid userId,
        Guid? targetQuizId,
        CancellationToken cancellationToken)
    {
        var max = generationOptions.Value.MaxQuestionsPerGeneration;
        var capped = Math.Clamp(questionCount <= 0 ? 15 : questionCount, 1, max);
        var importable = await ResolveImportableCountAsync(userId, targetQuizId, cancellationToken);
        return Math.Min(capped, importable > 0 ? importable : capped);
    }
}
