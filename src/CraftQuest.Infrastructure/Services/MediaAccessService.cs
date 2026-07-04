using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class MediaAccessService(CraftQuestDbContext dbContext) : IMediaAccessService
{
    public async Task EnsureCanReadAsync(
        Guid mediaAssetId,
        Guid? userId,
        Guid? guestVisitId,
        string? guestToken,
        CancellationToken cancellationToken = default)
    {
        var assetExists = await dbContext.MediaAssets
            .AsNoTracking()
            .AnyAsync(
                m => m.MediaAssetId == mediaAssetId && m.Status == "active",
                cancellationToken);

        if (!assetExists)
        {
            throw new AppException("Media asset not found.", 404);
        }

        if (userId.HasValue
            && await CanUserReadAsync(mediaAssetId, userId.Value, cancellationToken))
        {
            return;
        }

        if (guestVisitId.HasValue
            && !string.IsNullOrWhiteSpace(guestToken)
            && await CanGuestReadAsync(
                mediaAssetId,
                guestVisitId.Value,
                guestToken.Trim(),
                cancellationToken))
        {
            return;
        }

        if (await IsPublishedPrepCoverAsync(mediaAssetId, cancellationToken))
        {
            return;
        }

        throw new AppException("You do not have access to this media asset.", 403);
    }

    private async Task<bool> CanUserReadAsync(
        Guid mediaAssetId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        if (await dbContext.MediaAssets
                .AsNoTracking()
                .AnyAsync(
                    m => m.MediaAssetId == mediaAssetId && m.UploadedByUserId == userId,
                    cancellationToken))
        {
            return true;
        }

        if (await IsMediaInAuthorQuizAsync(mediaAssetId, userId, cancellationToken))
        {
            return true;
        }

        if (await IsMediaInAccessibleQuizAsync(mediaAssetId, userId, cancellationToken))
        {
            return true;
        }

        return await IsMediaInUserPracticeAsync(mediaAssetId, userId, cancellationToken);
    }

    private Task<bool> IsMediaInAuthorQuizAsync(
        Guid mediaAssetId,
        Guid userId,
        CancellationToken cancellationToken) =>
        dbContext.QuestionAnswerOptions
            .AsNoTracking()
            .AnyAsync(
                o => o.MediaAssetId == mediaAssetId
                    && o.IsActive
                    && o.Question.Quiz.CreatedByUserId == userId,
                cancellationToken);

    private Task<bool> IsMediaInAccessibleQuizAsync(
        Guid mediaAssetId,
        Guid userId,
        CancellationToken cancellationToken) =>
        dbContext.QuestionAnswerOptions
            .AsNoTracking()
            .AnyAsync(
                o => o.MediaAssetId == mediaAssetId
                    && o.IsActive
                    && (
                        dbContext.QuizAccesses.Any(a =>
                            a.QuizId == o.Question.QuizId && a.UserId == userId)
                        || dbContext.Assignments.Any(a =>
                            a.QuizId == o.Question.QuizId
                            && a.Status == "active"
                            && dbContext.ClassMembers.Any(m =>
                                m.ClassId == a.ClassId
                                && m.UserId == userId
                                && m.Status == "active"))),
                cancellationToken);

    private Task<bool> IsMediaInUserPracticeAsync(
        Guid mediaAssetId,
        Guid userId,
        CancellationToken cancellationToken) =>
        dbContext.PracticeAnswerOptionSnapshots
            .AsNoTracking()
            .AnyAsync(
                s => s.MediaAssetIdSnapshot == mediaAssetId
                    && s.PracticeQuestionSnapshot.PracticeSession.StudentUserId == userId,
                cancellationToken);

    private async Task<bool> CanGuestReadAsync(
        Guid mediaAssetId,
        Guid guestVisitId,
        string guestToken,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var visit = await dbContext.GuestVisits
            .AsNoTracking()
            .FirstOrDefaultAsync(
                v => v.GuestVisitId == guestVisitId
                    && v.Token == guestToken
                    && v.ExpiresAt > now,
                cancellationToken);

        if (visit is null)
        {
            return false;
        }

        return await dbContext.QuestionAnswerOptions
            .AsNoTracking()
            .AnyAsync(
                o => o.MediaAssetId == mediaAssetId
                    && o.IsActive
                    && o.Question.QuizId == visit.QuizId,
                cancellationToken);
    }

    private Task<bool> IsPublishedPrepCoverAsync(
        Guid mediaAssetId,
        CancellationToken cancellationToken) =>
        dbContext.PrepCatalogItems
            .AsNoTracking()
            .AnyAsync(
                i => i.CoverMediaId == mediaAssetId && i.IsPublished && !i.IsDeleted,
                cancellationToken);
}
