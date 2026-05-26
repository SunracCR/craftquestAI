using System.Text.Json;
using CraftQuest.Application.Models.Ai;
using CraftQuest.Application.Models.Imports;
using CraftQuest.Application.Models.StudyMaterials;
using CraftQuest.Domain.Entities;

namespace CraftQuest.Infrastructure.Services;

internal static class AiJobMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public static (int? PageFrom, int? PageTo, int? QuestionCount) ParseGenerationParameters(AiJob job)
    {
        if (string.IsNullOrWhiteSpace(job.InputJson))
        {
            return (null, null, null);
        }

        try
        {
            var p = JsonSerializer.Deserialize<QuizGenerationParametersDto>(job.InputJson, JsonOptions);
            if (p is null)
            {
                return (null, null, null);
            }

            return (
                p.PageFrom > 0 ? p.PageFrom : null,
                p.PageTo > 0 ? p.PageTo : null,
                p.QuestionCount > 0 ? p.QuestionCount : null);
        }
        catch
        {
            return (null, null, null);
        }
    }

    public static AiJobDto ToDto(AiJob job, CqifDocument? result, string? studyMaterialTitle)
    {
        var (pageFrom, pageTo, questionCount) = ParseGenerationParameters(job);
        return new AiJobDto
        {
            AiJobId = job.AiJobId,
            Status = job.Status,
            JobType = job.JobType,
            Stage = job.Stage,
            ProgressPercent = job.ProgressPercent,
            ErrorMessage = job.ErrorMessage,
            ErrorCode = job.ErrorCode,
            NextRetryAt = job.NextRetryAt,
            RetryAttempt = job.RetryAttempt,
            CreditsConsumed = job.CreditsConsumed,
            Result = result,
            QuestionImportBatchId = job.QuestionImportBatchId,
            TargetQuizId = job.TargetQuizId,
            StudyMaterialId = job.StudyMaterialId,
            StudyMaterialTitle = studyMaterialTitle,
            PageFrom = pageFrom,
            PageTo = pageTo,
            QuestionCount = questionCount,
            CreatedAt = job.CreatedAt,
            StartedAt = job.StartedAt,
            CompletedAt = job.CompletedAt,
        };
    }

    public static AiJobSummaryDto ToSummary(
        AiJob job,
        string? studyMaterialTitle,
        bool importReadyForReview)
    {
        var (pageFrom, pageTo, questionCount) = ParseGenerationParameters(job);
        return new AiJobSummaryDto
        {
            AiJobId = job.AiJobId,
            Status = job.Status,
            JobType = job.JobType,
            Stage = job.Stage,
            ProgressPercent = job.ProgressPercent,
            ErrorCode = job.ErrorCode,
            StudyMaterialId = job.StudyMaterialId,
            StudyMaterialTitle = studyMaterialTitle,
            TargetQuizId = job.TargetQuizId,
            QuestionImportBatchId = job.QuestionImportBatchId,
            ImportReadyForReview = importReadyForReview,
            PageFrom = pageFrom,
            PageTo = pageTo,
            QuestionCount = questionCount,
            CreatedAt = job.CreatedAt,
            CompletedAt = job.CompletedAt,
        };
    }
}
