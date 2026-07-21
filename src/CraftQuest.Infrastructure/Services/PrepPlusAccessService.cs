using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.PrepPlus;
using CraftQuest.Application.Services.PrepPlus;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusAccessService(CraftQuestDbContext dbContext) : IPrepPlusAccessService
{
    public async Task EnsureCanPurchaseOfferAsync(
        Guid userId,
        Guid quizId,
        bool isLifetimeOffer,
        CancellationToken cancellationToken = default)
    {
        var existing = await LoadPurchaseAccessAsync(userId, quizId, cancellationToken);
        if (PrepPlusAccessRules.HasOwnedAccess(ToSnapshot(existing)))
        {
            throw new AppException(
                "You already have permanent access to this quiz.",
                409,
                PrepPlusErrorCodes.AlreadyOwned);
        }

        if (!isLifetimeOffer && existing is { IsLifetimeAccess: true })
        {
            throw new AppException(
                "You already have permanent access to this quiz.",
                409,
                PrepPlusErrorCodes.AlreadyOwned);
        }
    }

    public async Task<PrepAccessGrantResult> GrantOrExtendPurchaseAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        bool isLifetimeAccess,
        int durationDays,
        Guid? purchaseId,
        CancellationToken cancellationToken = default)
    {
        if (isLifetimeAccess)
        {
            await EnsureCanPurchaseOfferAsync(userId, quizId, isLifetimeOffer: true, cancellationToken);
            return await GrantLifetimeAccessAsync(
                userId,
                catalogItemId,
                quizId,
                purchaseId,
                cancellationToken);
        }

        await EnsureCanPurchaseOfferAsync(userId, quizId, isLifetimeOffer: false, cancellationToken);

        var now = DateTime.UtcNow;
        var existing = await LoadPurchaseAccessAsync(userId, quizId, cancellationToken, track: true);

        var baseDate = existing?.AccessType == "purchase"
            && !existing.IsLifetimeAccess
            && existing.ExpiresAt > now
            ? existing.ExpiresAt!.Value
            : now;
        var expiresAt = baseDate.AddDays(durationDays);

        if (existing is null)
        {
            dbContext.QuizAccesses.Add(new QuizAccess
            {
                QuizAccessId = Guid.NewGuid(),
                UserId = userId,
                QuizId = quizId,
                AccessType = "purchase",
                GrantedAt = now,
                ExpiresAt = expiresAt,
                IsLifetimeAccess = false,
                GrantedByPurchaseId = purchaseId,
                PrepCatalogItemId = catalogItemId,
            });
        }
        else
        {
            var wasExpired = existing.AccessType != "purchase"
                || existing.IsLifetimeAccess
                || existing.ExpiresAt is null
                || existing.ExpiresAt <= now;
            existing.AccessType = "purchase";
            existing.IsLifetimeAccess = false;
            existing.ExpiresAt = expiresAt;
            existing.GrantedByPurchaseId = purchaseId ?? existing.GrantedByPurchaseId;
            existing.PrepCatalogItemId = catalogItemId;
            if (wasExpired)
            {
                existing.GrantedAt = now;
            }
        }

        return new PrepAccessGrantResult(expiresAt, IsLifetimeAccess: false);
    }

    private async Task<PrepAccessGrantResult> GrantLifetimeAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        Guid? purchaseId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var existing = await LoadPurchaseAccessAsync(userId, quizId, cancellationToken, track: true);

        if (existing is null)
        {
            dbContext.QuizAccesses.Add(new QuizAccess
            {
                QuizAccessId = Guid.NewGuid(),
                UserId = userId,
                QuizId = quizId,
                AccessType = "purchase",
                GrantedAt = now,
                ExpiresAt = null,
                IsLifetimeAccess = true,
                GrantedByPurchaseId = purchaseId,
                PrepCatalogItemId = catalogItemId,
            });
        }
        else
        {
            existing.AccessType = "purchase";
            existing.IsLifetimeAccess = true;
            existing.ExpiresAt = null;
            existing.GrantedByPurchaseId = purchaseId ?? existing.GrantedByPurchaseId;
            existing.PrepCatalogItemId = catalogItemId;
            existing.GrantedAt = now;
        }

        return new PrepAccessGrantResult(null, IsLifetimeAccess: true);
    }

    private Task<QuizAccess?> LoadPurchaseAccessAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken,
        bool track = false)
    {
        var query = track
            ? dbContext.QuizAccesses.AsQueryable()
            : dbContext.QuizAccesses.AsNoTracking();

        return query
            .Where(a => a.UserId == userId
                && a.QuizId == quizId
                && a.ClassId == null
                && a.AssignmentId == null)
            .OrderByDescending(a => a.IsLifetimeAccess)
            .ThenByDescending(a => a.ExpiresAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    private static QuizAccessSnapshot? ToSnapshot(QuizAccess? access) =>
        access is null
            ? null
            : new QuizAccessSnapshot(access.AccessType, access.IsLifetimeAccess, access.ExpiresAt);
}
