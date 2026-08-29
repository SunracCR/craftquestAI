using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Services.Imports;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Ai;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services;

public class QuestionImportService(
    CraftQuestDbContext dbContext,
    IQuizService quizService,
    IBillingService billingService,
    AiGenerationTraceContext trace,
    ILogger<QuestionImportService> logger) : IQuestionImportService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false,
    };

    private static readonly HashSet<string> SupportedSourceTypes =
        ["json", "txt", "raw_text", "xlsx"];

    public async Task<QuestionImportStatusDto> ProcessAsync(
        Guid userId,
        Guid quizId,
        ProcessImportRequest request,
        string? originalFileName = null,
        CancellationToken cancellationToken = default)
    {
        await EnsureQuizOwnerAsync(userId, quizId, cancellationToken);
        await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);

        var sourceType = request.SourceType.Trim().ToLowerInvariant();
        if (!SupportedSourceTypes.Contains(sourceType))
        {
            throw new AppException(
                $"Source type '{request.SourceType}' is not supported. Use json, txt, or xlsx via process-file.",
                501);
        }

        if (sourceType == "xlsx")
        {
            throw new AppException(
                "Upload xlsx files using POST .../question-imports/process-file.",
                400);
        }

        if (string.IsNullOrWhiteSpace(request.RawText))
        {
            throw new AppException("rawText is required for this import.", 400);
        }

        var document = ParseDocumentFromText(sourceType, request.RawText);

        return await PersistImportAsync(
            userId,
            quizId,
            document,
            sourceType == "raw_text" ? "txt" : sourceType,
            originalFileName,
            request.UseAiNormalization,
            cancellationToken);
    }

    public async Task<QuestionImportStatusDto> ProcessFileAsync(
        Guid userId,
        Guid quizId,
        Stream fileStream,
        string sourceType,
        string? originalFileName,
        bool useAiNormalization = false,
        CancellationToken cancellationToken = default)
    {
        await EnsureQuizOwnerAsync(userId, quizId, cancellationToken);
        await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);

        var normalizedType = sourceType.Trim().ToLowerInvariant();
        if (normalizedType != "xlsx")
        {
            throw new AppException(
                "process-file currently supports xlsx. Use process for json/txt.",
                400);
        }

        var document = CqifExcelParser.Parse(fileStream);

        return await PersistImportAsync(
            userId,
            quizId,
            document,
            "xlsx",
            originalFileName,
            useAiNormalization,
            cancellationToken);
    }

    private static CqifDocument ParseDocumentFromText(string sourceType, string rawText) =>
        sourceType switch
        {
            "json" => CqifJsonParser.Parse(rawText),
            "txt" or "raw_text" => CqifTxtParser.Parse(rawText),
            _ => throw new AppException("Unsupported source type.", 400),
        };

    private async Task<QuestionImportStatusDto> PersistImportAsync(
        Guid userId,
        Guid quizId,
        CqifDocument document,
        string sourceType,
        string? originalFileName,
        bool useAiNormalization,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstAsync(q => q.QuizId == quizId, cancellationToken);
        CqifDocumentNormalizer.ApplyQuizDefaults(document, quiz.DefaultQuestionPoints);

        var documentIssues = CqifValidator.ValidateDocument(document)
            .Where(i => i.Severity == "error")
            .ToList();

        if (documentIssues.Count > 0 && document.Questions.Count == 0)
        {
            throw new AppException(documentIssues[0].Message, 400);
        }

        var batchId = Guid.NewGuid();
        var batch = new QuestionImportBatch
        {
            QuestionImportBatchId = batchId,
            QuizId = quizId,
            UploadedByUserId = userId,
            SourceType = sourceType,
            OriginalFileName = originalFileName,
            Status = "parsing",
            UseAiNormalization = useAiNormalization,
            CqifVersion = document.CqifVersion,
            CreatedAt = DateTime.UtcNow,
        };

        var warningCount = PopulateBatchFromDocument(batch, document, documentIssues);
        dbContext.QuestionImportBatches.Add(batch);

        if (string.Equals(sourceType, "ai", StringComparison.OrdinalIgnoreCase) && trace.IsActive)
        {
            var rowSamples = batch.Rows
                .OrderBy(r => r.RowNumber)
                .Select(r =>
                {
                    var firstError = batch.Errors
                        .FirstOrDefault(e => e.QuestionImportRowId == r.QuestionImportRowId);
                    return (r.RowNumber, r.Status, firstError?.ErrorCode, firstError?.ErrorMessage);
                })
                .ToList();

            trace.ImportBatchSnapshot(
                "import.populate",
                batch.TotalRows,
                batch.ValidRows,
                batch.ErrorRows,
                batch.Status,
                rowSamples);
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        return MapStatus(batch, warningCount);
    }

    public Task<QuestionImportStatusDto> CreateBatchFromDocumentAsync(
        Guid userId,
        Guid quizId,
        CqifDocument document,
        string sourceType,
        string? originalFileName,
        CancellationToken cancellationToken = default) =>
        PersistImportAsync(
            userId,
            quizId,
            document,
            sourceType,
            originalFileName,
            useAiNormalization: false,
            cancellationToken);

    public async Task<QuestionImportStatusDto> ApplyCqifDocumentAsync(
        Guid userId,
        Guid importId,
        CqifDocument document,
        CancellationToken cancellationToken = default)
    {
        var batch = await LoadOwnedBatchAsync(userId, importId, cancellationToken);

        if (batch.Status is "confirmed" or "completed" or "completed_with_errors")
        {
            throw new AppException("Import batch was already confirmed.", 400);
        }

        dbContext.QuestionImportErrors.RemoveRange(batch.Errors);
        dbContext.QuestionImportRows.RemoveRange(batch.Rows);
        batch.Errors.Clear();
        batch.Rows.Clear();
        batch.CqifVersion = document.CqifVersion;
        batch.UseAiNormalization = true;
        batch.Status = "parsing";

        var documentIssues = CqifValidator.ValidateDocument(document)
            .Where(i => i.Severity == "error")
            .ToList();

        if (batch.QuizId is Guid linkedQuizId)
        {
            var quiz = await dbContext.Quizzes
                .AsNoTracking()
                .FirstAsync(q => q.QuizId == linkedQuizId, cancellationToken);
            CqifDocumentNormalizer.ApplyQuizDefaults(document, quiz.DefaultQuestionPoints);
        }

        var warningCount = PopulateBatchFromDocument(batch, document, documentIssues);
        await dbContext.SaveChangesAsync(cancellationToken);

        return MapStatus(batch, warningCount);
    }

    public async Task<QuestionImportPreviewDto> GetPreviewAsync(
        Guid userId,
        Guid importId,
        CancellationToken cancellationToken = default)
    {
        var batch = await LoadOwnedBatchAsync(userId, importId, cancellationToken);

        var warningCount = batch.Rows.Count(r => r.Status == "warning");
        var validRows = batch.Rows
            .Where(r => r.Status is "valid" or "warning")
            .OrderBy(r => r.RowNumber)
            .ToList();

        var questions = validRows
            .Select(r => JsonSerializer.Deserialize<CqifQuestion>(r.CqifQuestionJson!, JsonOptions)!)
            .ToList();

        int? importableCount = questions.Count;
        int? maxPerQuiz = null;
        var currentInQuiz = 0;
        string? planName = null;

        if (batch.QuizId is Guid previewQuizId)
        {
            var capacity = await billingService.GetQuizQuestionCapacityAsync(
                userId,
                previewQuizId,
                cancellationToken);
            importableCount = Math.Min(questions.Count, capacity.RemainingSlots);
            maxPerQuiz = capacity.MaxQuestionsPerQuiz;
            currentInQuiz = capacity.CurrentQuestionCount;
            planName = capacity.PlanName;
        }

        return new QuestionImportPreviewDto
        {
            ImportId = batch.QuestionImportBatchId,
            Status = batch.Status,
            TotalQuestionsDetected = batch.TotalRows,
            ValidQuestions = batch.ValidRows,
            QuestionsWithWarnings = warningCount,
            QuestionsWithErrors = batch.ErrorRows,
            Questions = questions,
            ImportableQuestionCount = importableCount,
            MaxQuestionsPerQuiz = maxPerQuiz,
            CurrentQuestionCountInQuiz = currentInQuiz,
            PlanName = planName,
            Errors = batch.Errors
                .OrderBy(e => e.CreatedAt)
                .Select(e => new ImportErrorDto
                {
                    RowNumber = batch.Rows.FirstOrDefault(r => r.QuestionImportRowId == e.QuestionImportRowId)?.RowNumber,
                    FieldName = e.FieldName,
                    ErrorCode = e.ErrorCode,
                    Message = e.ErrorMessage,
                    Severity = e.Severity,
                })
                .ToList(),
        };
    }

    public async Task<QuestionImportConfirmResultDto> ConfirmAsync(
        Guid userId,
        Guid importId,
        CancellationToken cancellationToken = default)
    {
        var batch = await LoadOwnedBatchAsync(userId, importId, cancellationToken);

        if (batch.Status is "confirmed" or "completed" or "completed_with_errors")
        {
            return await MapCompletedConfirmResultAsync(userId, batch, cancellationToken);
        }

        if (batch.QuizId is null)
        {
            throw new AppException("Import batch is not linked to a quiz.", 400);
        }

        if (batch.ValidRows == 0)
        {
            throw new AppException("No valid questions to import.", 400);
        }

        var quizId = batch.QuizId.Value;
        await billingService.EnsureCanModifyOwnedQuizzesAsync(userId, cancellationToken);
        var batchId = batch.QuestionImportBatchId;
        var quizDefaultPoints = await dbContext.Quizzes
            .AsNoTracking()
            .Where(q => q.QuizId == quizId)
            .Select(q => q.DefaultQuestionPoints)
            .FirstAsync(cancellationToken);
        var capacity = await billingService.GetQuizQuestionCapacityAsync(
            userId,
            quizId,
            cancellationToken);
        var createdIds = new List<Guid>();
        var confirmErrors = new List<QuestionImportError>();
        var skippedDueToPlanLimit = 0;

        var sortOrder = await dbContext.Questions
            .Where(q => q.QuizId == quizId)
            .MaxAsync(q => (int?)q.SortOrder, cancellationToken) ?? 0;

        var quiz = await dbContext.Quizzes
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId != userId)
        {
            throw new AppException("You do not have permission to modify this quiz.", 403);
        }

        var questionTypes = await dbContext.QuestionTypes
            .AsNoTracking()
            .Where(t => t.IsActive)
            .ToDictionaryAsync(t => t.Code, StringComparer.OrdinalIgnoreCase, cancellationToken);

        var sectionNameMap = await dbContext.QuizSections
            .Where(s => s.QuizId == quizId)
            .ToDictionaryAsync(s => s.Name, s => s.QuizSectionId, StringComparer.OrdinalIgnoreCase, cancellationToken);

        foreach (var row in batch.Rows.OrderBy(r => r.RowNumber))
        {
            if (row.Status is not ("valid" or "warning"))
            {
                continue;
            }

            if (capacity.MaxQuestionsPerQuiz.HasValue
                && createdIds.Count >= capacity.RemainingSlots)
            {
                row.Status = "skipped";
                skippedDueToPlanLimit++;
                continue;
            }

            var question = JsonSerializer.Deserialize<CqifQuestion>(row.CqifQuestionJson!, JsonOptions)!;
            var createRequest = CqifImportMapper.ToCreateQuestionRequest(question, quizDefaultPoints);
            createRequest.SectionId = await ResolveImportChapterSectionIdAsync(
                quizId,
                question.Chapter,
                sectionNameMap,
                cancellationToken);
            if (string.Equals(batch.SourceType, "ai", StringComparison.OrdinalIgnoreCase))
            {
                createRequest.IsGeneratedByAi = true;
            }

            if (!questionTypes.TryGetValue(createRequest.QuestionType, out var questionType))
            {
                row.Status = "error";
                confirmErrors.Add(new QuestionImportError
                {
                    QuestionImportErrorId = Guid.NewGuid(),
                    QuestionImportBatchId = batchId,
                    QuestionImportRowId = row.QuestionImportRowId,
                    FieldName = "questionType",
                    ErrorCode = "INVALID_QUESTION_TYPE",
                    ErrorMessage = $"Invalid question type '{createRequest.QuestionType}'.",
                    Severity = "error",
                    CreatedAt = DateTime.UtcNow,
                });
                continue;
            }

            try
            {
                sortOrder++;
                var created = await quizService.CreateQuestionAsync(
                    userId,
                    quizId,
                    createRequest,
                    cancellationToken,
                    saveChanges: false,
                    explicitSortOrder: sortOrder,
                    skipBillingChecks: true,
                    preloadedQuiz: quiz,
                    preloadedQuestionType: questionType);

                createdIds.Add(created.QuestionId);
                row.Status = "created";
                row.CreatedQuestionId = created.QuestionId;
            }
            catch (Exception ex)
            {
                row.Status = "error";
                confirmErrors.Add(new QuestionImportError
                {
                    QuestionImportErrorId = Guid.NewGuid(),
                    QuestionImportBatchId = batchId,
                    QuestionImportRowId = row.QuestionImportRowId,
                    FieldName = "confirm",
                    ErrorCode = "CONFIRM_FAILED",
                    ErrorMessage = ex is AppException ? ex.Message : "Question could not be imported.",
                    Severity = "error",
                    CreatedAt = DateTime.UtcNow,
                });
                if (ex is not AppException)
                {
                    logger.LogError(
                        ex,
                        "Unexpected error confirming import row {RowNumber} for batch {BatchId}",
                        row.RowNumber,
                        batchId);
                }
            }
        }

        if (confirmErrors.Count > 0)
        {
            dbContext.QuestionImportErrors.AddRange(confirmErrors);
        }

        var skipped = batch.Rows.Count(r => r.Status is not "created");
        batch.Status = skipped > 0 && createdIds.Count > 0
            ? "completed_with_errors"
            : createdIds.Count > 0
                ? "completed"
                : "failed";
        batch.CompletedAt = DateTime.UtcNow;
        batch.ValidRows = createdIds.Count;
        batch.ErrorRows = batch.Rows.Count(r => r.Status == "error");

        await dbContext.SaveChangesAsync(cancellationToken);

        return new QuestionImportConfirmResultDto
        {
            ImportId = batch.QuestionImportBatchId,
            CreatedQuestions = createdIds.Count,
            SkippedQuestions = skipped,
            SkippedDueToPlanLimit = skippedDueToPlanLimit,
            MaxQuestionsPerQuiz = capacity.MaxQuestionsPerQuiz,
            PlanName = capacity.PlanName,
            CreatedQuestionIds = createdIds,
        };
    }

    private async Task<QuestionImportConfirmResultDto> MapCompletedConfirmResultAsync(
        Guid userId,
        QuestionImportBatch batch,
        CancellationToken cancellationToken)
    {
        QuizQuestionCapacityDto? capacity = null;
        if (batch.QuizId is Guid quizId)
        {
            capacity = await billingService.GetQuizQuestionCapacityAsync(
                userId,
                quizId,
                cancellationToken);
        }

        var createdIds = batch.Rows
            .Where(r => r.CreatedQuestionId is not null)
            .OrderBy(r => r.RowNumber)
            .Select(r => r.CreatedQuestionId!.Value)
            .ToList();

        return new QuestionImportConfirmResultDto
        {
            ImportId = batch.QuestionImportBatchId,
            CreatedQuestions = createdIds.Count,
            SkippedQuestions = batch.Rows.Count(r => r.Status is not "created"),
            SkippedDueToPlanLimit = batch.Rows.Count(r => r.Status == "skipped"),
            MaxQuestionsPerQuiz = capacity?.MaxQuestionsPerQuiz,
            PlanName = capacity?.PlanName,
            CreatedQuestionIds = createdIds,
        };
    }

    private async Task<QuestionImportBatch> LoadOwnedBatchAsync(
        Guid userId,
        Guid importId,
        CancellationToken cancellationToken)
    {
        var batch = await dbContext.QuestionImportBatches
            .Include(b => b.Rows)
            .Include(b => b.Errors)
            .FirstOrDefaultAsync(b => b.QuestionImportBatchId == importId, cancellationToken)
            ?? throw new AppException("Import batch not found.", 404);

        if (batch.UploadedByUserId != userId)
        {
            throw new AppException("Import batch not found.", 404);
        }

        return batch;
    }

    private async Task EnsureQuizOwnerAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken)
    {
        var quiz = await dbContext.Quizzes
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.QuizId == quizId, cancellationToken)
            ?? throw new AppException("Quiz not found.", 404);

        if (quiz.CreatedByUserId != userId)
        {
            throw new AppException("You do not have permission to modify this quiz.", 403);
        }
    }

    private static int PopulateBatchFromDocument(
        QuestionImportBatch batch,
        CqifDocument document,
        List<CqifValidationIssue> documentIssues)
    {
        var warningCount = 0;
        var errorCount = 0;
        var validCount = 0;
        var rowNumber = 0;

        foreach (var question in document.Questions)
        {
            rowNumber++;
            var rowIssues = CqifValidator.ValidateQuestion(question, rowNumber);
            var hasError = rowIssues.Any(i => i.Severity == "error");
            var hasWarning = rowIssues.Any(i => i.Severity == "warning");

            if (hasWarning)
            {
                warningCount++;
            }

            if (hasError)
            {
                errorCount++;
            }
            else
            {
                validCount++;
            }

            var rowId = Guid.NewGuid();
            var row = new QuestionImportRow
            {
                QuestionImportRowId = rowId,
                QuestionImportBatchId = batch.QuestionImportBatchId,
                RowNumber = rowNumber,
                CqifQuestionJson = JsonSerializer.Serialize(question, JsonOptions),
                Status = hasError ? "error" : hasWarning ? "warning" : "valid",
                CreatedAt = DateTime.UtcNow,
            };

            batch.Rows.Add(row);

            foreach (var issue in rowIssues)
            {
                batch.Errors.Add(new QuestionImportError
                {
                    QuestionImportErrorId = Guid.NewGuid(),
                    QuestionImportBatchId = batch.QuestionImportBatchId,
                    QuestionImportRowId = rowId,
                    FieldName = issue.FieldName,
                    ErrorCode = issue.ErrorCode,
                    ErrorMessage = issue.Message,
                    Severity = issue.Severity,
                    CreatedAt = DateTime.UtcNow,
                });
            }
        }

        foreach (var issue in documentIssues)
        {
            batch.Errors.Add(new QuestionImportError
            {
                QuestionImportErrorId = Guid.NewGuid(),
                QuestionImportBatchId = batch.QuestionImportBatchId,
                FieldName = issue.FieldName,
                ErrorCode = issue.ErrorCode,
                ErrorMessage = issue.Message,
                Severity = issue.Severity,
                CreatedAt = DateTime.UtcNow,
            });
            if (issue.Severity == "error")
            {
                errorCount++;
            }
        }

        batch.TotalRows = document.Questions.Count;
        batch.ValidRows = validCount;
        batch.ErrorRows = errorCount;
        batch.Status = validCount > 0 ? "ready_for_review" : "failed";

        return warningCount;
    }

    private static QuestionImportStatusDto MapStatus(QuestionImportBatch batch, int warningCount) =>
        new()
        {
            ImportId = batch.QuestionImportBatchId,
            Status = batch.Status,
            TotalQuestionsDetected = batch.TotalRows,
            ValidQuestions = batch.ValidRows,
            QuestionsWithWarnings = warningCount,
            QuestionsWithErrors = batch.ErrorRows,
        };

    private async Task<Guid?> ResolveImportChapterSectionIdAsync(
        Guid quizId,
        string? chapterName,
        Dictionary<string, Guid> sectionNameMap,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(chapterName))
        {
            return null;
        }

        var normalizedName = chapterName.Trim();
        if (sectionNameMap.TryGetValue(normalizedName, out var existingId))
        {
            return existingId;
        }

        var maxSortOrder = await dbContext.QuizSections
            .Where(s => s.QuizId == quizId)
            .MaxAsync(s => (int?)s.SortOrder, cancellationToken) ?? 0;

        var section = new QuizSection
        {
            QuizSectionId = Guid.NewGuid(),
            QuizId = quizId,
            Name = normalizedName,
            SortOrder = maxSortOrder + 1,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.QuizSections.Add(section);
        sectionNameMap[normalizedName] = section.QuizSectionId;
        return section.QuizSectionId;
    }
}
