using CraftQuest.Application.Constants;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Models.Notifications;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Notifications;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace CraftQuest.Infrastructure.Services;

public class BillingService(
    CraftQuestDbContext dbContext,
    IMemoryCache memoryCache,
    INotificationService notificationService,
    ILogger<BillingService> logger) : IBillingService
{
    private static readonly TimeSpan BillingCacheDuration = TimeSpan.FromSeconds(45);

    public async Task<UserBillingDto> GetMyBillingAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var cacheKey = BillingCacheKey(userId);
        if (memoryCache.TryGetValue(cacheKey, out UserBillingDto? cached) && cached is not null)
        {
            return cached;
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var plan = subscription.Plan;

        await EnsureMonthlyAiCreditsAsync(userId, subscription, cancellationToken);
        await EnsureAiCreditBalanceMatchesPlanAsync(userId, subscription, cancellationToken);

        var monthStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        // EF Core: un DbContext no admite consultas concurrentes.
        var quizzesCreated = await CountOwnedQuizzesAsync(userId, cancellationToken);
        var shareCodesThisMonth = await dbContext.ShareCodes
            .AsNoTracking()
            .CountAsync(
                s => s.CreatedByUserId == userId && s.CreatedAt >= monthStart,
                cancellationToken);
        var redeemedSharedCount = await CountRedeemedSharedQuizzesAsync(userId, cancellationToken);
        var creditBalances = await GetCreditBalancesByTypeAsync(userId, cancellationToken);
        var canInviteDirectly = await CanInviteUsersDirectlyAsync(userId, plan.Code, cancellationToken);
        var baseEntitlements = MapEntitlements(plan, redeemedSharedCount);

        var dto = new UserBillingDto
        {
            Plan = MapPlan(plan),
            Subscription = MapSubscription(subscription),
            Usage = new BillingUsageDto
            {
                QuizzesCreated = quizzesCreated,
                ShareCodesCreatedThisMonth = shareCodesThisMonth,
            },
            Entitlements = new PlanEntitlementsDto
            {
                MaxQuizzes = baseEntitlements.MaxQuizzes,
                MaxQuestionsPerQuiz = baseEntitlements.MaxQuestionsPerQuiz,
                MonthlyAiCredits = baseEntitlements.MonthlyAiCredits,
                MonthlyShareCodes = baseEntitlements.MonthlyShareCodes,
                MaxRedeemedSharedQuizzes = baseEntitlements.MaxRedeemedSharedQuizzes,
                CurrentRedeemedSharedQuizzes = baseEntitlements.CurrentRedeemedSharedQuizzes,
                CanInviteUsersDirectly = canInviteDirectly,
                QuizModificationLocked = IsQuizModificationLocked(plan, quizzesCreated),
            },
            Credits = new CreditBalancesDto
            {
                AiCredits = GetBalanceFromMap(creditBalances, BillingCreditTypes.AiPlan)
                    + GetBalanceFromMap(creditBalances, BillingCreditTypes.AiPurchased),
                ShareCodeCredits = GetBalanceFromMap(creditBalances, BillingCreditTypes.ShareCode),
            },
        };

        memoryCache.Set(cacheKey, dto, BillingCacheDuration);
        return dto;
    }

    public async Task<IReadOnlyList<PurchaseHistoryItemDto>> GetMyPurchasesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        const int maxItems = 100;
        var purchases = await dbContext.Purchases
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.PurchasedAt ?? p.CreatedAt)
            .Take(maxItems)
            .ToListAsync(cancellationToken);

        if (purchases.Count == 0)
        {
            return [];
        }

        var planNames = await ResolvePlanNamesAsync(purchases, cancellationToken);
        var prepTitles = await ResolvePrepCatalogTitlesAsync(purchases, cancellationToken);

        return purchases
            .Select(p => new PurchaseHistoryItemDto
            {
                PurchaseId = p.PurchaseId,
                ProductCode = p.ProductCode,
                ProductDisplayName = ResolveProductDisplayName(p, planNames, prepTitles),
                ProductType = p.ProductType,
                ProviderCode = p.ProviderCode,
                Amount = p.Amount,
                CurrencyCode = p.CurrencyCode,
                Status = p.Status,
                PurchasedAt = p.PurchasedAt,
                CreatedAt = p.CreatedAt,
            })
            .ToList();
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

        var count = await CountOwnedQuizzesAsync(userId, cancellationToken);

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

    public async Task EnsureCanModifyOwnedQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var cacheKey = $"billing:quiz-modify-ok:{userId}";
        if (memoryCache.TryGetValue(cacheKey, out bool allowed) && allowed)
        {
            return;
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        var maxQuizzes = subscription.Plan.MaxQuizzes;
        if (!maxQuizzes.HasValue)
        {
            memoryCache.Set(cacheKey, true, BillingCacheDuration);
            return;
        }

        var count = await CountOwnedQuizzesAsync(userId, cancellationToken);
        if (count <= maxQuizzes.Value)
        {
            memoryCache.Set(cacheKey, true, BillingCacheDuration);
            return;
        }

        throw new AppException(
            $"Quiz modification locked: {count} quizzes exceed plan limit ({maxQuizzes.Value}) for '{subscription.Plan.Code}'.",
            403,
            "QUIZ_OVER_PLAN_LIMIT",
            new Dictionary<string, object?>
            {
                ["maxQuizzes"] = maxQuizzes.Value,
                ["currentQuizzes"] = count,
                ["planCode"] = subscription.Plan.Code,
                ["planName"] = subscription.Plan.Name,
            });
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
            .CountAsync(q => q.QuizId == quizId, cancellationToken);

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
        await EnsureMonthlyAiCreditsAsync(userId, subscription, cancellationToken);
        await EnsureAiCreditBalanceMatchesPlanAsync(userId, subscription, cancellationToken);

        var balance = await GetTotalAiCreditsBalanceAsync(userId, cancellationToken);
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
        await EnsureHasAiCreditsAsync(userId, amount, cancellationToken);

        var remaining = amount;
        var planBalance = await GetCreditBalanceAsync(
            userId,
            BillingCreditTypes.AiPlan,
            cancellationToken);
        if (remaining > 0 && planBalance > 0)
        {
            var fromPlan = Math.Min(remaining, planBalance);
            var newPlanBalance = planBalance - fromPlan;
            dbContext.CreditLedgerEntries.Add(new CreditLedgerEntry
            {
                CreditLedgerId = Guid.NewGuid(),
                UserId = userId,
                CreditType = BillingCreditTypes.AiPlan,
                Delta = -fromPlan,
                BalanceAfter = newPlanBalance,
                Reason = "consume",
                ReferenceType = referenceType,
                ReferenceId = referenceId,
                CreatedAt = DateTime.UtcNow,
            });
            remaining -= fromPlan;
        }

        if (remaining > 0)
        {
            var purchasedBalance = await GetCreditBalanceAsync(
                userId,
                BillingCreditTypes.AiPurchased,
                cancellationToken);
            var newPurchasedBalance = purchasedBalance - remaining;
            dbContext.CreditLedgerEntries.Add(new CreditLedgerEntry
            {
                CreditLedgerId = Guid.NewGuid(),
                UserId = userId,
                CreditType = BillingCreditTypes.AiPurchased,
                Delta = -remaining,
                BalanceAfter = newPurchasedBalance,
                Reason = "consume",
                ReferenceType = referenceType,
                ReferenceId = referenceId,
                CreatedAt = DateTime.UtcNow,
            });
        }

        if (saveImmediately)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            InvalidateBillingCache(userId);
        }
    }

    public async Task<int> GrantPurchasedAiCreditsAsync(
        Guid userId,
        int amount,
        Guid purchaseId,
        CancellationToken cancellationToken = default)
    {
        if (amount <= 0)
        {
            throw new AppException("Invalid credit amount.", 400);
        }

        var subscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        if (subscription.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException(
                "AI credit packs are not available on the Free plan. Upgrade to Pro or Teacher first.",
                403,
                "AI_CREDIT_PACKS_NOT_AVAILABLE");
        }

        await EnsureMonthlyAiCreditsAsync(userId, subscription, cancellationToken);

        var purchasedBalance = await GetCreditBalanceAsync(
            userId,
            BillingCreditTypes.AiPurchased,
            cancellationToken);
        var newPurchasedBalance = purchasedBalance + amount;
        dbContext.CreditLedgerEntries.Add(new CreditLedgerEntry
        {
            CreditLedgerId = Guid.NewGuid(),
            UserId = userId,
            CreditType = BillingCreditTypes.AiPurchased,
            Delta = amount,
            BalanceAfter = newPurchasedBalance,
            Reason = "purchase",
            ReferenceType = "purchase",
            ReferenceId = purchaseId,
            CreatedAt = DateTime.UtcNow,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetTotalAiCreditsBalanceAsync(userId, cancellationToken);
    }

    public async Task ActivatePlanAsync(
        Guid userId,
        string planCode,
        string providerCode,
        string? providerSubscriptionId,
        SubscriptionActivationOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        var plan = await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == planCode && p.IsActive, cancellationToken)
            ?? throw new AppException($"Plan '{planCode}' is not available.", 400);

        if (plan.Code == "free")
        {
            throw new AppException("Cannot activate the free plan through payments.", 400);
        }

        options ??= new SubscriptionActivationOptions();
        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(options.BillingCycle);
        var now = options.PeriodStart ?? DateTime.UtcNow;
        var periodEnd = options.PeriodEnd
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(now, billingCycle);
        var isRecurring = SubscriptionPeriodCalculator.IsRecurringProvider(providerCode);

        var activeSubscriptions = await dbContext.UserSubscriptions
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .ToListAsync(cancellationToken);

        foreach (var subscription in activeSubscriptions)
        {
            subscription.Status = SubscriptionStatuses.Cancelled;
            subscription.EndsAt = now;
        }

        dbContext.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = plan.PlanId,
            Status = SubscriptionStatuses.Active,
            StartedAt = now,
            EndsAt = periodEnd,
            ProviderCode = providerCode,
            ProviderSubscriptionId = providerSubscriptionId,
            CreatedAt = now,
            BillingCycle = billingCycle,
            AutoRenewEnabled = isRecurring && options.AutoRenewEnabled,
            CancelAtPeriodEnd = options.CancelAtPeriodEnd,
            LastPaymentAt = options.LastPaymentAt ?? now,
        });

        if (plan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                BillingCreditTypes.AiPlan,
                plan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await SyncTeacherRoleAsync(userId, plan.IsTeacherPlan, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<CancelAutoRenewResponse> CancelAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AppException("No active subscription.", 404);

        if (subscription.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Free plan has no auto-renewal to cancel.", 400);
        }

        subscription.AutoRenewEnabled = false;
        subscription.CancelAtPeriodEnd = true;

        var accessUntil = subscription.EndsAt
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(
                subscription.StartedAt,
                subscription.BillingCycle);

        if (subscription.EndsAt is null)
        {
            subscription.EndsAt = accessUntil;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var manageInStore = SubscriptionPeriodCalculator.IsMobileStoreProvider(subscription.ProviderCode);

        return new CancelAutoRenewResponse
        {
            AccessUntil = accessUntil,
            AutoRenewEnabled = false,
            ProviderCode = subscription.ProviderCode,
            ManageInStore = manageInStore,
        };
    }

    public async Task<ReactivateAutoRenewResponse> ReactivateAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AppException("No active subscription.", 404);

        if (subscription.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException("Free plan has no auto-renewal to reactivate.", 400);
        }

        if (!SubscriptionPeriodCalculator.IsRecurringProvider(subscription.ProviderCode))
        {
            throw new AppException("This subscription does not support auto-renewal.", 400);
        }

        if (subscription.AutoRenewEnabled && !subscription.CancelAtPeriodEnd)
        {
            throw new AppException("Auto-renewal is already enabled.", 400);
        }

        var accessUntil = subscription.EndsAt
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(
                subscription.StartedAt,
                subscription.BillingCycle);

        if (accessUntil <= DateTime.UtcNow)
        {
            throw new AppException("The paid period has already ended.", 400);
        }

        subscription.AutoRenewEnabled = true;
        subscription.CancelAtPeriodEnd = false;

        if (subscription.EndsAt is null)
        {
            subscription.EndsAt = accessUntil;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var manageInStore = SubscriptionPeriodCalculator.IsMobileStoreProvider(subscription.ProviderCode);

        return new ReactivateAutoRenewResponse
        {
            AutoRenewEnabled = true,
            NextRenewalAt = accessUntil,
            ProviderCode = subscription.ProviderCode,
            ManageInStore = manageInStore,
            RequiresResubscribe = false,
        };
    }

    public async Task CancelSubscriptionAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is not null
            && !subscription.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase)
            && SubscriptionPeriodCalculator.IsRecurringProvider(subscription.ProviderCode))
        {
            await CancelAutoRenewAsync(userId, cancellationToken);
            return;
        }

        await DowngradeToFreePlanAsync(userId, cancellationToken);
    }

    public async Task<int> ProcessExpiredSubscriptionsAsync(
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var graceThreshold = now.AddDays(-3);

        var toExpire = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.Status == SubscriptionStatuses.Active
                        && s.EndsAt != null
                        && s.EndsAt <= now
                        && !s.Plan.Code.Equals("free")
                        && (s.CancelAtPeriodEnd
                            || !s.AutoRenewEnabled
                            || s.EndsAt <= graceThreshold))
            .ToListAsync(cancellationToken);

        var count = 0;
        foreach (var group in toExpire.GroupBy(s => s.UserId))
        {
            await DowngradeToFreePlanAsync(group.Key, cancellationToken);
            count++;
        }

        return count;
    }

    public async Task RenewSubscriptionPeriodAsync(
        string providerSubscriptionId,
        string providerCode,
        DateTime? periodEnd,
        string? paymentTransactionId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.ProviderSubscriptionId == providerSubscriptionId
                        && s.ProviderCode == providerCode
                        && s.Status == SubscriptionStatuses.Active)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AppException("Subscription not found for renewal.", 404);

        var now = DateTime.UtcNow;
        subscription.LastPaymentAt = now;
        subscription.AutoRenewEnabled = true;
        subscription.CancelAtPeriodEnd = false;
        subscription.EndsAt = periodEnd
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(now, subscription.BillingCycle);

        if (!string.IsNullOrWhiteSpace(paymentTransactionId))
        {
            var exists = await dbContext.Purchases.AnyAsync(
                p => p.ProviderCode == providerCode
                     && p.ProviderTransactionId == paymentTransactionId,
                cancellationToken);

            if (!exists)
            {
                dbContext.Purchases.Add(new Purchase
                {
                    PurchaseId = Guid.NewGuid(),
                    UserId = subscription.UserId,
                    ProductCode = subscription.Plan.Code,
                    ProductType = "subscription",
                    ProviderCode = providerCode,
                    ProviderTransactionId = paymentTransactionId,
                    Amount = subscription.BillingCycle == BillingCycles.Annual
                        ? subscription.Plan.AnnualPrice
                        : subscription.Plan.MonthlyPrice,
                    CurrencyCode = "USD",
                    Status = "validated",
                    PurchasedAt = now,
                    CreatedAt = now,
                });
            }
        }

        if (subscription.Plan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                subscription.UserId,
                BillingCreditTypes.AiPlan,
                subscription.Plan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task DowngradeToFreePlanAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var active = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
            .ToListAsync(cancellationToken);

        var wasTeacherPlan = active.Any(s => s.Plan.IsTeacherPlan);
        var expiredPlanName = active.FirstOrDefault()?.Plan.Name ?? "Premium";

        foreach (var sub in active)
        {
            sub.Status = SubscriptionStatuses.Cancelled;
            sub.EndsAt = now;
            sub.AutoRenewEnabled = false;
        }

        var freePlan = await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == "free" && p.IsActive, cancellationToken)
            ?? throw new AppException("Free plan is not configured.", 500);

        dbContext.UserSubscriptions.Add(new UserSubscription
        {
            UserSubscriptionId = Guid.NewGuid(),
            UserId = userId,
            PlanId = freePlan.PlanId,
            Status = SubscriptionStatuses.Active,
            StartedAt = now,
            ProviderCode = "internal",
            CreatedAt = now,
            BillingCycle = BillingCycles.Monthly,
            AutoRenewEnabled = false,
            CancelAtPeriodEnd = false,
        });

        if (wasTeacherPlan)
        {
            await SyncTeacherRoleAsync(userId, false, cancellationToken);
        }

        if (freePlan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                BillingCreditTypes.AiPlan,
                freePlan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        await NotificationPublisher.TryNotifyAsync(
            () => notificationService.NotifyAsync(
                userId,
                NotificationTypes.MembershipExpired,
                new NotificationPayload
                {
                    PlanName = expiredPlanName,
                    Route = "profile/billing",
                },
                $"membership_expired:{userId}:{DateTime.UtcNow:yyyyMMdd}",
                cancellationToken),
            logger,
            "membership_expired");
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
            Status = SubscriptionStatuses.Active,
            StartedAt = now,
            CreatedAt = now,
            BillingCycle = BillingCycles.Monthly,
            AutoRenewEnabled = false,
            CancelAtPeriodEnd = false,
        });

        if (freePlan.MonthlyAiCredits > 0)
        {
            await SetCreditBalanceAsync(
                userId,
                BillingCreditTypes.AiPlan,
                freePlan.MonthlyAiCredits,
                "grant_plan",
                cancellationToken,
                saveImmediately: false);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateBillingCache(userId);
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

    private Task<int> GetCreditBalanceAsync(
        Guid userId,
        string creditType,
        CancellationToken cancellationToken) =>
        dbContext.CreditLedgerEntries
            .AsNoTracking()
            .Where(e => e.UserId == userId && e.CreditType == creditType)
            .SumAsync(e => e.Delta, cancellationToken);

    /// <summary>
    /// Corrige el saldo IA al cupo del plan activo si el usuario no ha consumido créditos
    /// en el periodo actual (calendario o ciclo de suscripción).
    /// </summary>
    private async Task EnsureAiCreditBalanceMatchesPlanAsync(
        Guid userId,
        UserSubscription subscription,
        CancellationToken cancellationToken)
    {
        var plan = subscription.Plan;
        if (plan.MonthlyAiCredits <= 0)
        {
            return;
        }

        var periodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            DateTime.UtcNow);

        var consumedThisPeriod = await dbContext.CreditLedgerEntries
            .AnyAsync(
                e => e.UserId == userId
                    && e.CreditType == BillingCreditTypes.AiPlan
                    && e.Reason == "consume"
                    && e.CreatedAt >= periodStart,
                cancellationToken);

        if (consumedThisPeriod)
        {
            return;
        }

        var balance = await GetCreditBalanceAsync(
            userId,
            BillingCreditTypes.AiPlan,
            cancellationToken);
        if (balance == plan.MonthlyAiCredits)
        {
            return;
        }

        await SetCreditBalanceAsync(
            userId,
            BillingCreditTypes.AiPlan,
            plan.MonthlyAiCredits,
            "grant_plan",
            cancellationToken);
    }

    private async Task EnsureMonthlyAiCreditsAsync(
        Guid userId,
        UserSubscription subscription,
        CancellationToken cancellationToken)
    {
        var plan = subscription.Plan;
        if (plan.MonthlyAiCredits <= 0)
        {
            return;
        }

        var periodStart = AiCreditPeriodCalculator.GetCreditPeriodStartUtc(
            subscription,
            plan,
            DateTime.UtcNow);

        var refreshedThisPeriod = await dbContext.CreditLedgerEntries
            .AnyAsync(
                e => e.UserId == userId
                    && e.CreditType == BillingCreditTypes.AiPlan
                    && (e.Reason == "grant_plan" || e.Reason == "monthly_reset")
                    && e.CreatedAt >= periodStart,
                cancellationToken);

        if (refreshedThisPeriod)
        {
            return;
        }

        await SetCreditBalanceAsync(
            userId,
            BillingCreditTypes.AiPlan,
            plan.MonthlyAiCredits,
            "monthly_reset",
            cancellationToken);
    }

    private async Task<int> GetTotalAiCreditsBalanceAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await GetCreditBalanceAsync(userId, BillingCreditTypes.AiPlan, cancellationToken)
        + await GetCreditBalanceAsync(userId, BillingCreditTypes.AiPurchased, cancellationToken);

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
            InvalidateBillingCache(userId);
        }
    }

    private static string BillingCacheKey(Guid userId) => $"billing:me:{userId:D}";

    private void InvalidateBillingCache(Guid userId) =>
        memoryCache.Remove(BillingCacheKey(userId));

    private static int GetBalanceFromMap(IReadOnlyDictionary<string, int> balances, string creditType) =>
        balances.TryGetValue(creditType, out var balance) ? balance : 0;

    private async Task<Dictionary<string, int>> GetCreditBalancesByTypeAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var rows = await dbContext.CreditLedgerEntries
            .AsNoTracking()
            .Where(e => e.UserId == userId)
            .GroupBy(e => e.CreditType)
            .Select(g => new { CreditType = g.Key, Balance = g.Sum(e => e.Delta) })
            .ToListAsync(cancellationToken);

        return rows.ToDictionary(r => r.CreditType, r => r.Balance, StringComparer.OrdinalIgnoreCase);
    }

    private static SubscriptionDto MapSubscription(UserSubscription subscription)
    {
        var recurring = SubscriptionPeriodCalculator.IsRecurringProvider(subscription.ProviderCode)
            && !subscription.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase);

        return new SubscriptionDto
        {
            Status = subscription.Status,
            StartedAt = subscription.StartedAt,
            EndsAt = subscription.EndsAt,
            BillingCycle = subscription.BillingCycle,
            AutoRenewEnabled = subscription.AutoRenewEnabled,
            CancelAtPeriodEnd = subscription.CancelAtPeriodEnd,
            LastPaymentAt = subscription.LastPaymentAt,
            NextBillingAt = subscription.AutoRenewEnabled && !subscription.CancelAtPeriodEnd
                ? subscription.EndsAt
                : null,
            ProviderCode = subscription.ProviderCode,
            IsRecurring = recurring,
        };
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
        int quizzesCreated,
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
            QuizModificationLocked = IsQuizModificationLocked(plan, quizzesCreated),
        };
    }

    private static bool IsQuizModificationLocked(Plan plan, int quizzesCreated) =>
        plan.MaxQuizzes is int max && quizzesCreated > max;

    private Task<int> CountOwnedQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        dbContext.Quizzes
            .CountAsync(q => q.CreatedByUserId == userId, cancellationToken);

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

    private async Task<Dictionary<string, string>> ResolvePlanNamesAsync(
        IReadOnlyList<Purchase> purchases,
        CancellationToken cancellationToken)
    {
        var planCodes = purchases
            .Where(p => p.ProductType == "subscription")
            .Select(p => p.ProductCode)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (planCodes.Count == 0)
        {
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }

        return await dbContext.Plans
            .AsNoTracking()
            .Where(p => planCodes.Contains(p.Code))
            .ToDictionaryAsync(p => p.Code, p => p.Name, StringComparer.OrdinalIgnoreCase, cancellationToken);
    }

    private async Task<Dictionary<Guid, string>> ResolvePrepCatalogTitlesAsync(
        IReadOnlyList<Purchase> purchases,
        CancellationToken cancellationToken)
    {
        var catalogIds = purchases
            .Where(p => p.ProductType == "prep_access")
            .Select(p => TryParsePrepCatalogItemId(p.ProductCode))
            .Where(id => id.HasValue)
            .Select(id => id!.Value)
            .Distinct()
            .ToList();

        if (catalogIds.Count == 0)
        {
            return [];
        }

        var items = await dbContext.PrepCatalogItems
            .AsNoTracking()
            .Include(c => c.Quiz)
            .Where(c => catalogIds.Contains(c.CatalogItemId))
            .Select(c => new
            {
                c.CatalogItemId,
                Title = c.TitleOverride ?? c.Quiz.Title,
            })
            .ToListAsync(cancellationToken);

        return items.ToDictionary(i => i.CatalogItemId, i => i.Title);
    }

    private static Guid? TryParsePrepCatalogItemId(string productCode)
    {
        var parts = productCode.Split('|', StringSplitOptions.TrimEntries);
        return parts.Length >= 1 && Guid.TryParse(parts[0], out var catalogItemId)
            ? catalogItemId
            : null;
    }

    private static string? ResolveProductDisplayName(
        Purchase purchase,
        IReadOnlyDictionary<string, string> planNames,
        IReadOnlyDictionary<Guid, string> prepTitles)
    {
        if (purchase.ProductType == "subscription"
            && planNames.TryGetValue(purchase.ProductCode, out var planName))
        {
            return planName;
        }

        if (purchase.ProductType == "prep_access"
            && TryParsePrepCatalogItemId(purchase.ProductCode) is { } catalogItemId
            && prepTitles.TryGetValue(catalogItemId, out var prepTitle))
        {
            return prepTitle;
        }

        if (purchase.ProductType == "ai_credits")
        {
            return purchase.ProductCode;
        }

        return null;
    }

    private async Task<int> CountRedeemedSharedQuizzesAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.QuizAccesses
            .AsNoTracking()
            .Where(a => a.UserId == userId
                && a.AssignmentId == null
                && a.AccessType == "redeemed")
            .Join(
                dbContext.Quizzes,
                a => a.QuizId,
                q => q.QuizId,
                (a, _) => a.QuizId)
            .Distinct()
            .CountAsync(cancellationToken);
}

