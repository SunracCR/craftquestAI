using CraftQuest.Application.Constants;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class BillingService(CraftQuestDbContext dbContext) : IBillingService
{
    public async Task<UserBillingDto> GetMyBillingAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var plan = subscription.Plan;

        await EnsureMonthlyAiCreditsAsync(userId, plan, cancellationToken);

        var quizzesCreated = await dbContext.Quizzes
            .CountAsync(q => q.CreatedByUserId == userId && q.DeletedAt == null, cancellationToken);

        var monthStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var shareCodesThisMonth = await dbContext.ShareCodes
            .CountAsync(
                s => s.CreatedByUserId == userId && s.CreatedAt >= monthStart,
                cancellationToken);

        var redeemedSharedCount = await CountRedeemedSharedQuizzesAsync(userId, cancellationToken);

        return new UserBillingDto
        {
            Plan = MapPlan(plan),
            Subscription = new SubscriptionDto
            {
                Status = subscription.Status,
                StartedAt = subscription.StartedAt,
                EndsAt = subscription.EndsAt,
            },
            Usage = new BillingUsageDto
            {
                QuizzesCreated = quizzesCreated,
                ShareCodesCreatedThisMonth = shareCodesThisMonth,
            },
            Entitlements = await MapEntitlementsAsync(
                userId,
                plan,
                redeemedSharedCount,
                cancellationToken),
            Credits = new CreditBalancesDto
            {
                AiCredits = await GetCreditBalanceAsync(userId, "ai", cancellationToken),
                ShareCodeCredits = await GetCreditBalanceAsync(userId, "share_code", cancellationToken),
            },
        };
    }

    public async Task EnsureCanCreateQuizAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var maxQuizzes = subscription.Plan.MaxQuizzes;
        if (!maxQuizzes.HasValue)
        {
            return;
        }

        var count = await dbContext.Quizzes
            .CountAsync(q => q.CreatedByUserId == userId && q.DeletedAt == null, cancellationToken);

        if (count >= maxQuizzes.Value)
        {
            throw new AppException(
                $"Quiz limit reached ({maxQuizzes.Value}) for plan '{subscription.Plan.Code}'.",
                403,
                "QUIZ_LIMIT_REACHED",
                new Dictionary<string, object?>
                {
                    ["maxQuizzes"] = maxQuizzes.Value,
                    ["planCode"] = subscription.Plan.Code,
                    ["planName"] = subscription.Plan.Name,
                });
        }
    }

    public async Task EnsureCanAddQuestionAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var capacity = await GetQuizQuestionCapacityAsync(userId, quizId, cancellationToken);
        if (capacity.MaxQuestionsPerQuiz.HasValue && capacity.RemainingSlots <= 0)
        {
            throw new AppException(
                $"Question limit reached ({capacity.MaxQuestionsPerQuiz.Value}) for plan '{capacity.PlanCode}'.",
                403,
                "QUESTION_LIMIT_REACHED",
                new Dictionary<string, object?>
                {
                    ["maxQuestionsPerQuiz"] = capacity.MaxQuestionsPerQuiz.Value,
                    ["planCode"] = capacity.PlanCode,
                    ["planName"] = capacity.PlanName,
                });
        }
    }

    public async Task<QuizQuestionCapacityDto> GetQuizQuestionCapacityAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var plan = subscription.Plan;
        var currentCount = await dbContext.Questions
            .CountAsync(q => q.QuizId == quizId && q.DeletedAt == null, cancellationToken);

        var remaining = plan.MaxQuestionsPerQuiz.HasValue
            ? Math.Max(0, plan.MaxQuestionsPerQuiz.Value - currentCount)
            : int.MaxValue;

        return new QuizQuestionCapacityDto
        {
            PlanCode = plan.Code,
            PlanName = plan.Name,
            MaxQuestionsPerQuiz = plan.MaxQuestionsPerQuiz,
            CurrentQuestionCount = currentCount,
            RemainingSlots = remaining,
        };
    }

    public Task EnsureCanCreateShareCodeAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        Task.CompletedTask;

    public async Task EnsureCanRedeemSharedQuizAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default)
    {
        var alreadyHasAccess = await dbContext.QuizAccesses.AnyAsync(
            a => a.UserId == userId
                && a.QuizId == quizId
                && a.AssignmentId == null
                && a.AccessType == "redeemed",
            cancellationToken);

        if (alreadyHasAccess)
        {
            return;
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var max = GetMaxRedeemedSharedQuizzes(subscription.Plan.Code);
        if (!max.HasValue)
        {
            return;
        }

        var current = await CountRedeemedSharedQuizzesAsync(userId, cancellationToken);
        if (current >= max.Value)
        {
            throw new AppException(
                $"Shared quiz slot limit reached ({max.Value}) for plan '{subscription.Plan.Code}'.",
                403,
                "SHARED_QUIZ_SLOT_LIMIT",
                new Dictionary<string, object?>
                {
                    ["max"] = max.Value,
                    ["current"] = current,
                });
        }
    }

    public async Task EnsureCanInviteUserToQuizAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        if (!await CanInviteUsersDirectlyAsync(userId, subscription.Plan.Code, cancellationToken))
        {
            throw new AppException(
                "Direct user invitations require a Pro or Teacher plan.",
                403,
                "DIRECT_INVITE_NOT_ALLOWED");
        }
    }

    public async Task EnsureHasAiCreditsAsync(
        Guid userId,
        int amount,
        CancellationToken cancellationToken = default)
    {
        if (amount <= 0)
        {
            return;
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        await EnsureMonthlyAiCreditsAsync(userId, subscription.Plan, cancellationToken);

        var balance = await GetCreditBalanceAsync(userId, "ai", cancellationToken);
        if (balance < amount)
        {
            throw new AppException(
                $"Insufficient AI credits. Required: {amount}, available: {balance}.",
                403,
                "AI_CREDITS_INSUFFICIENT",
                new Dictionary<string, object?>
                {
                    ["required"] = amount,
                    ["available"] = balance,
                });
        }
    }

    public async Task ConsumeAiCreditsAsync(
        Guid userId,
        int amount,
        string? referenceType,
        Guid? referenceId,
        CancellationToken cancellationToken = default,
        bool saveImmediately = true)
    {
        if (amount <= 0)
        {
            return;
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        await EnsureMonthlyAiCreditsAsync(userId, subscription.Plan, cancellationToken);

        await EnsureHasAiCreditsAsync(userId, amount, cancellationToken);
        var balance = await GetCreditBalanceAsync(userId, "ai", cancellationToken) - amount;

        dbContext.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = "ai",
            Delta = -amount,
            BalanceAfter = balance,
            Reason = "consume",
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            CreatedAt = DateTime.UtcNow,
        });

        if (saveImmediately)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task ActivatePlanAsync(
        Guid userId,
        string planCode,
        string providerCode,
        string? providerSubscriptionId,
        CancellationToken cancellationToken = default)
    {
        var plan = await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == planCode && p.IsActive, cancellationToken)
            ?? throw new AppException($"Plan '{planCode}' is not available.", 400);

        if (plan.Code == "free")
        {
            throw new AppException("Cannot activate the free plan through payments.", 400);
        }

        var now = DateTime.UtcNow;
        var activeSubscriptions = await dbContext.UserSubscriptions
            .Where(s => s.UserId == userId && s.Status == "active")
            .ToListAsync(cancellationToken);

        foreach (var subscription in activeSubscriptions)
        {
            subscription.Status = "cancelled";
            subscription.EndsAt = now;
        }

        dbContext.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = plan.PlanId,
            Status = "active",
            StartedAt = now,
            ProviderCode = providerCode,
            ProviderSubscriptionId = providerSubscriptionId,
            CreatedAt = now,
        });

        if (plan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                "ai",
                plan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        // Asignar/revocar rol teacher según el plan activado
        await SyncTeacherRoleAsync(userId, plan.IsTeacherPlan, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task CancelSubscriptionAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var active = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .ToListAsync(cancellationToken);

        var wasTeacherPlan = active.Any(s => s.Plan.IsTeacherPlan);

        foreach (var sub in active)
        {
            sub.Status = "cancelled";
            sub.EndsAt = now;
        }

        // Volver al plan free
        var freePlan = await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == "free" && p.IsActive, cancellationToken)
            ?? throw new AppException("Free plan is not configured.", 500);

        dbContext.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = freePlan.PlanId,
            Status = "active",
            StartedAt = now,
            ProviderCode = "internal",
            CreatedAt = now,
        });

        // Revocar rol teacher si venía de un plan teacher
        if (wasTeacherPlan)
        {
            await SyncTeacherRoleAsync(userId, false, cancellationToken);
        }

        if (freePlan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                "ai",
                freePlan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> IsSubscriptionExpiringAsync(
        Guid userId,
        int withinDays = 7,
        CancellationToken cancellationToken = default)
    {
        var threshold = DateTime.UtcNow.AddDays(withinDays);
        return await dbContext.UserSubscriptions
            .AnyAsync(
                s => s.UserId == userId
                     && s.Status == "active"
                     && s.EndsAt != null
                     && s.EndsAt <= threshold,
                cancellationToken);
    }

    /// <summary>
    /// Inserta el rol "teacher" si <paramref name="grant"/> es true.
    /// Lo elimina si es false y el usuario lo tiene.
    /// </summary>
    private async Task SyncTeacherRoleAsync(
        Guid userId,
        bool grant,
        CancellationToken cancellationToken)
    {
        var teacherRole = await dbContext.Roles
            .FirstOrDefaultAsync(r => r.Code == RoleCodes.Teacher, cancellationToken);

        if (teacherRole is null) return;

        var existing = await dbContext.UserRoles
            .FirstOrDefaultAsync(
                ur => ur.UserId == userId && ur.RoleId == teacherRole.RoleId,
                cancellationToken);

        if (grant && existing is null)
        {
            dbContext.UserRoles.Add(new UserRole
            {
                UserId = userId,
                RoleId = teacherRole.RoleId,
                CreatedAt = DateTime.UtcNow,
            });
        }
        else if (!grant && existing is not null)
        {
            dbContext.UserRoles.Remove(existing);
        }
    }

    public async Task AssignFreePlanAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var hasSubscription = await dbContext.UserSubscriptions
            .AnyAsync(
                s => s.UserId == userId && s.Status == "active",
                cancellationToken);

        if (hasSubscription)
        {
            return;
        }

        var freePlan = await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == "free" && p.IsActive, cancellationToken)
            ?? throw new AppException("Free plan is not configured.", 500);

        var now = DateTime.UtcNow;
        dbContext.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = freePlan.PlanId,
            Status = "active",
            StartedAt = now,
            CreatedAt = now,
        });

        if (freePlan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                "ai",
                freePlan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<UserSubscription> GetActiveSubscriptionAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is null)
        {
            await AssignFreePlanAsync(userId, cancellationToken);
            subscription = await dbContext.UserSubscriptions
                .Include(s => s.Plan)
                .Where(s => s.UserId == userId && s.Status == "active")
                .OrderByDescending(s => s.StartedAt)
                .FirstAsync(cancellationToken);
        }

        return subscription;
    }

    private async Task<int> GetCreditBalanceAsync(
        Guid userId,
        string creditType,
        CancellationToken cancellationToken)
    {
        var entries = await dbContext.CreditLedgerEntries
            .Where(e => e.UserId == userId && e.CreditType == creditType)
            .Select(e => e.Delta)
            .ToListAsync(cancellationToken);

        return entries.Sum();
    }

    private async Task EnsureMonthlyAiCreditsAsync(
        Guid userId,
        Plan plan,
        CancellationToken cancellationToken)
    {
        if (plan.MonthlyAiCredits <= 0)
        {
            return;
        }

        var monthStart = new DateTime(
            DateTime.UtcNow.Year,
            DateTime.UtcNow.Month,
            1,
            0,
            0,
            0,
            DateTimeKind.Utc);

        var refreshedThisMonth = await dbContext.CreditLedgerEntries
            .AnyAsync(
                e => e.UserId == userId
                    && e.CreditType == "ai"
                    && (e.Reason == "grant_plan" || e.Reason == "reset_monthly")
                    && e.CreatedAt >= monthStart,
                cancellationToken);

        if (refreshedThisMonth)
        {
            return;
        }

        await SetCreditBalanceAsync(
            userId,
            "ai",
            plan.MonthlyAiCredits,
            "reset_monthly",
            cancellationToken);
    }

    private async Task SetCreditBalanceAsync(
        Guid userId,
        string creditType,
        int targetBalance,
        string reason,
        CancellationToken cancellationToken,
        bool saveImmediately = true)
    {
        var currentBalance = await GetCreditBalanceAsync(userId, creditType, cancellationToken);
        if (currentBalance == targetBalance)
        {
            return;
        }

        dbContext.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = creditType,
            Delta = targetBalance - currentBalance,
            BalanceAfter = targetBalance,
            Reason = reason,
            CreatedAt = DateTime.UtcNow,
        });

        if (saveImmediately)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    private static PlanDto MapPlan(Plan plan) => new()
    {
        Code = plan.Code,
        Name = plan.Name,
        MonthlyPrice = plan.MonthlyPrice,
        AnnualPrice = plan.AnnualPrice,
        IsTeacherPlan = plan.IsTeacherPlan,
        IsInstitutionPlan = plan.IsInstitutionPlan,
    };

    private static PlanEntitlementsDto MapEntitlements(Plan plan, int redeemedSharedCount) => new()
    {
        MaxQuizzes = plan.MaxQuizzes,
        MaxQuestionsPerQuiz = plan.MaxQuestionsPerQuiz,
        MonthlyAiCredits = plan.MonthlyAiCredits,
        MonthlyShareCodes = plan.MonthlyShareCodes,
        MaxRedeemedSharedQuizzes = GetMaxRedeemedSharedQuizzes(plan.Code),
        CurrentRedeemedSharedQuizzes = redeemedSharedCount,
        CanInviteUsersDirectly = false,
    };

    private async Task<PlanEntitlementsDto> MapEntitlementsAsync(
        Guid userId,
        Plan plan,
        int redeemedSharedCount,
        CancellationToken cancellationToken)
    {
        var baseEntitlements = MapEntitlements(plan, redeemedSharedCount);
        return new PlanEntitlementsDto
        {
            MaxQuizzes = baseEntitlements.MaxQuizzes,
            MaxQuestionsPerQuiz = baseEntitlements.MaxQuestionsPerQuiz,
            MonthlyAiCredits = baseEntitlements.MonthlyAiCredits,
            MonthlyShareCodes = baseEntitlements.MonthlyShareCodes,
            MaxRedeemedSharedQuizzes = baseEntitlements.MaxRedeemedSharedQuizzes,
            CurrentRedeemedSharedQuizzes = baseEntitlements.CurrentRedeemedSharedQuizzes,
            CanInviteUsersDirectly = await CanInviteUsersDirectlyAsync(
                userId,
                plan.Code,
                cancellationToken),
        };
    }

    private async Task<bool> CanInviteUsersDirectlyAsync(
        Guid userId,
        string planCode,
        CancellationToken cancellationToken)
    {
        if (await HasTeacherRoleAsync(userId, cancellationToken))
        {
            return true;
        }

        return planCode.Equals("pro", StringComparison.OrdinalIgnoreCase)
            || planCode.Equals("teacher", StringComparison.OrdinalIgnoreCase)
            || planCode.Equals("institution", StringComparison.OrdinalIgnoreCase);
    }

    private async Task<bool> HasTeacherRoleAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.UserRoles
            .AsNoTracking()
            .AnyAsync(
                ur => ur.UserId == userId && ur.Role.Code == RoleCodes.Teacher,
                cancellationToken);

    private static int? GetMaxRedeemedSharedQuizzes(string planCode) =>
        planCode.Equals("free", StringComparison.OrdinalIgnoreCase)
            ? SharingLimits.FreeMaxRedeemedSharedQuizzes
            : null;

    private async Task<int> CountRedeemedSharedQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId
                && a.AssignmentId == null
                && a.AccessType == "redeemed")
            .Join(
                dbContext.Quizzes.Where(q => q.DeletedAt == null),
                a => a.QuizId,
                q => q.QuizId,
                (a, _) => a.QuizId)
            .Distinct()
            .CountAsync(cancellationToken);
}

