using CraftQuest.Application.Contracts;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class PrepPlusAccessService(CraftQuestDbContext dbContext) : IPrepPlusAccessService
{
    public async Task<DateTime> GrantOrExtendPurchaseAccessAsync(
        Guid userId,
        Guid catalogItemId,
        Guid quizId,
        int durationDays,
        Guid? purchaseId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        // Una sola fila por (UserId, QuizId, ClassId, AssignmentId); puede existir acceso redeemed previo.
        var existing = await dbContext.QuizAccesses
            .FirstOrDefaultAsync(
                a => a.UserId == userId
                    && a.QuizId == quizId
                    && a.ClassId == null
                    && a.AssignmentId == null,
                cancellationToken);

        var baseDate = existing?.AccessType == "purchase" && existing.ExpiresAt > now
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
                GrantedByPurchaseId = purchaseId,
                PrepCatalogItemId = catalogItemId,
            });
        }
        else
        {
            var wasExpired = existing.AccessType != "purchase"
                || existing.ExpiresAt is null
                || existing.ExpiresAt <= now;
            existing.AccessType = "purchase";
            existing.ExpiresAt = expiresAt;
            existing.GrantedByPurchaseId = purchaseId ?? existing.GrantedByPurchaseId;
            existing.PrepCatalogItemId = catalogItemId;
            if (wasExpired)
            {
                existing.GrantedAt = now;
            }
        }

        return expiresAt;
    }
}
