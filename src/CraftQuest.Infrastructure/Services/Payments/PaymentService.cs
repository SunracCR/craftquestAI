using System.Text.Json;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Billing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public class PaymentService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    PayPalApiClient payPalApiClient,
    IMobileStoreSubscriptionVerifier mobileStoreVerifier,
    MobileStoreWebhookProcessor mobileStoreWebhooks,
    IOptions<PaymentOptions> options) : IPaymentService
{
    private static readonly HashSet<string> PaidPlanCodes = ["pro", "teacher"];

    public async Task<IReadOnlyList<UpgradeablePlanDto>> GetUpgradeablePlansAsync(
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var paymentOptions = options.Value;
        var plans = await dbContext.Plans
            .AsNoTracking()
            .Where(p => p.IsActive && PaidPlanCodes.Contains(p.Code))
            .OrderBy(p => p.MonthlyPrice)
            .ToListAsync(cancellationToken);

        UserBillingDto? userBilling = null;
        if (userId.HasValue)
        {
            userBilling = await billingService.GetMyBillingAsync(userId.Value, cancellationToken);
            var currentRank = GetPlanRank(userBilling.Plan.Code);
            plans = plans.Where(p => GetPlanRank(p.Code) > currentRank).ToList();
        }

        var result = plans.Select(plan => MapUpgradeablePlan(plan, paymentOptions)).ToList();

        if (userBilling is not null
            && GetPlanRank(userBilling.Plan.Code) >= GetPlanRank("teacher"))
        {
            var institution = await dbContext.Plans
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    p => p.IsActive && p.Code == "institution",
                    cancellationToken);

            if (institution is not null
                && result.All(p => !p.Code.Equals("institution", StringComparison.OrdinalIgnoreCase)))
            {
                result.Add(MapUpgradeablePlan(institution, paymentOptions));
            }
        }

        return result;
    }

    private static UpgradeablePlanDto MapUpgradeablePlan(
        Plan plan,
        PaymentOptions paymentOptions)
    {
        paymentOptions.PlanProducts.TryGetValue(plan.Code, out var mapping);
        return new UpgradeablePlanDto
        {
            Code = plan.Code,
            Name = plan.Name,
            MonthlyPrice = plan.MonthlyPrice,
            AnnualPrice = plan.AnnualPrice,
            GooglePlayProductId = mapping?.GooglePlayProductId,
            GooglePlayAnnualProductId = mapping?.GooglePlayAnnualProductId,
            AppStoreProductId = mapping?.AppStoreProductId,
            AppStoreAnnualProductId = mapping?.AppStoreAnnualProductId,
            RequiresContactSales = !plan.MonthlyPrice.HasValue && !plan.AnnualPrice.HasValue,
            MonthlyAiCredits = plan.MonthlyAiCredits,
            MonthlyShareCodes = plan.MonthlyShareCodes,
        };
    }

    public async Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        PayPalCreateOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var plan = await GetPaidPlanAsync(request.PlanCode, cancellationToken);
        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(request.BillingCycle);
        var amount = ResolvePrice(plan, billingCycle);
        var purchaseId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        if (options.Value.UseMockPayments)
        {
            var mockOrderId = $"MOCK-{purchaseId:N}";
            await CreatePurchaseAsync(
                purchaseId,
                userId,
                plan.Code,
                "paypal",
                mockOrderId,
                amount,
                "pending",
                now,
                cancellationToken,
                billingCycle);

            return new PayPalCreateOrderResponse
            {
                PurchaseId = purchaseId,
                OrderId = mockOrderId,
                ApprovalUrl = null,
                MockMode = true,
            };
        }

        var (orderId, approvalUrl) = await payPalApiClient.CreateOrderAsync(
            amount,
            options.Value.CurrencyCode,
            $"CraftQuest {plan.Name}",
            cancellationToken);

        await CreatePurchaseAsync(
            purchaseId,
            userId,
            plan.Code,
            "paypal",
            orderId,
            amount,
            "pending",
            now,
            cancellationToken,
            billingCycle);

        return new PayPalCreateOrderResponse
        {
            PurchaseId = purchaseId,
            OrderId = orderId,
            ApprovalUrl = approvalUrl,
            MockMode = false,
        };
    }

    public async Task<PayPalCaptureOrderResponse> CapturePayPalOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var purchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.UserId == userId &&
                     p.ProviderCode == "paypal" &&
                     p.ProviderTransactionId == request.OrderId,
                cancellationToken)
            ?? throw new AppException("PayPal purchase not found.", 404);

        if (purchase.ProductType == "prep_access")
        {
            throw new AppException(
                "This order is a Preparación+ purchase. Use POST /api/prep/paypal/capture-order.",
                400);
        }

        if (purchase.ProductType == "ai_credits")
        {
            throw new AppException(
                "This order is an AI credits purchase. Use POST /api/billing/paypal/capture-ai-credit-order.",
                400);
        }

        if (purchase.Status == "validated")
        {
            return await BuildValidatedCaptureResponseAsync(
                userId,
                purchase,
                request.OrderId,
                cancellationToken);
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        var billingCycle = await ResolveBillingCycleFromPurchaseAsync(purchase, cancellationToken);
        var now = DateTime.UtcNow;
        await billingService.ActivatePlanAsync(
            userId,
            purchase.ProductCode,
            "paypal",
            request.OrderId,
            new SubscriptionActivationOptions
            {
                BillingCycle = billingCycle,
                AutoRenewEnabled = false,
                PeriodStart = now,
                PeriodEnd = SubscriptionPeriodCalculator.CalculatePeriodEnd(now, billingCycle),
                LastPaymentAt = now,
            },
            cancellationToken);

        await CompletePurchaseAsync(purchase, cancellationToken);

        return new PayPalCaptureOrderResponse
        {
            PlanCode = purchase.ProductCode,
            Status = "validated",
            MockMode = options.Value.UseMockPayments,
        };
    }

    public async Task<PayPalCreateSubscriptionResponse> CreatePayPalSubscriptionAsync(
        Guid userId,
        PayPalCreateSubscriptionRequest request,
        CancellationToken cancellationToken = default)
    {
        var plan = await GetPaidPlanAsync(request.PlanCode, cancellationToken);
        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(request.BillingCycle);
        var payPalPlanId = ResolvePayPalPlanId(plan.Code, billingCycle);
        var purchaseId = Guid.NewGuid();
        var now = DateTime.UtcNow;

        if (options.Value.UseMockPayments)
        {
            var mockSubId = $"MOCK-SUB-{purchaseId:N}";
        await CreatePurchaseAsync(
            purchaseId,
            userId,
            plan.Code,
            "paypal",
            mockSubId,
            ResolvePrice(plan, billingCycle),
            "pending",
            now,
            cancellationToken,
            billingCycle);

            return new PayPalCreateSubscriptionResponse
            {
                PurchaseId = purchaseId,
                SubscriptionId = mockSubId,
                ApprovalUrl = null,
                MockMode = true,
            };
        }

        if (string.IsNullOrWhiteSpace(payPalPlanId))
        {
            throw new AppException(
                $"PayPal subscription plan id not configured for '{plan.Code}' ({billingCycle}).",
                503);
        }

        var (subscriptionId, approvalUrl) = await payPalApiClient.CreateSubscriptionAsync(
            payPalPlanId,
            purchaseId.ToString(),
            cancellationToken);

        await CreatePurchaseAsync(
            purchaseId,
            userId,
            plan.Code,
            "paypal",
            subscriptionId,
            ResolvePrice(plan, billingCycle),
            "pending",
            now,
            cancellationToken,
            billingCycle);

        return new PayPalCreateSubscriptionResponse
        {
            PurchaseId = purchaseId,
            SubscriptionId = subscriptionId,
            ApprovalUrl = approvalUrl,
            MockMode = false,
        };
    }

    public async Task<PayPalActivateSubscriptionResponse> ActivatePayPalSubscriptionAsync(
        Guid userId,
        PayPalActivateSubscriptionRequest request,
        CancellationToken cancellationToken = default)
    {
        var purchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.UserId == userId
                     && p.ProviderCode == "paypal"
                     && p.ProviderTransactionId == request.SubscriptionId,
                cancellationToken)
            ?? throw new AppException("PayPal subscription purchase not found.", 404);

        if (purchase.Status == "validated")
        {
            return await BuildValidatedSubscriptionActivationResponseAsync(
                userId,
                purchase,
                request.SubscriptionId,
                request.BillingCycle,
                cancellationToken);
        }

        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(
            request.BillingCycle
            ?? purchase.BillingCycle
            ?? await ResolveBillingCycleFromPurchaseAsync(purchase, cancellationToken));
        DateTime? periodEnd = null;

        if (!options.Value.UseMockPayments)
        {
            var details = await payPalApiClient.GetSubscriptionAsync(
                request.SubscriptionId,
                cancellationToken);
            periodEnd = details.NextBillingTime;
        }

        var now = DateTime.UtcNow;
        periodEnd ??= SubscriptionPeriodCalculator.CalculatePeriodEnd(now, billingCycle);

        await billingService.ActivatePlanAsync(
            userId,
            purchase.ProductCode,
            "paypal",
            request.SubscriptionId,
            new SubscriptionActivationOptions
            {
                BillingCycle = billingCycle,
                AutoRenewEnabled = true,
                PeriodStart = now,
                PeriodEnd = periodEnd,
                LastPaymentAt = now,
            },
            cancellationToken);

        await CompletePurchaseAsync(purchase, cancellationToken);

        return new PayPalActivateSubscriptionResponse
        {
            PlanCode = purchase.ProductCode,
            Status = "validated",
            CurrentPeriodEnd = periodEnd,
            AutoRenewEnabled = true,
            MockMode = options.Value.UseMockPayments,
        };
    }

    public async Task RevokeProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        // Google Play y App Store: la cancelación de cobro solo puede hacerse en la tienda.
        if (subscription is null
            || string.IsNullOrWhiteSpace(subscription.ProviderSubscriptionId)
            || subscription.ProviderCode != "paypal"
            || options.Value.UseMockPayments)
        {
            return;
        }

        await payPalApiClient.CancelSubscriptionAtPeriodEndAsync(
            subscription.ProviderSubscriptionId,
            "User requested cancellation",
            cancellationToken);
    }

    public async Task<ProviderAutoRenewRestoreResult> TryRestoreProviderAutoRenewAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var subscription = await dbContext.UserSubscriptions
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is null)
        {
            throw new AppException("No active subscription.", 404);
        }

        var providerCode = subscription.ProviderCode;

        if (SubscriptionPeriodCalculator.IsMobileStoreProvider(providerCode))
        {
            return new ProviderAutoRenewRestoreResult
            {
                CanUpdateBilling = true,
                ManageInStore = true,
                ProviderCode = providerCode,
            };
        }

        if (subscription.ProviderCode != "paypal"
            || string.IsNullOrWhiteSpace(subscription.ProviderSubscriptionId)
            || options.Value.UseMockPayments)
        {
            return new ProviderAutoRenewRestoreResult
            {
                CanUpdateBilling = true,
                ProviderCode = providerCode,
            };
        }

        var details = await payPalApiClient.GetSubscriptionAsync(
            subscription.ProviderSubscriptionId,
            cancellationToken);

        if (string.Equals(details.Status, "CANCELLED", StringComparison.OrdinalIgnoreCase))
        {
            return new ProviderAutoRenewRestoreResult
            {
                CanUpdateBilling = false,
                RequiresResubscribe = true,
                ProviderCode = "paypal",
            };
        }

        if (string.Equals(details.Status, "SUSPENDED", StringComparison.OrdinalIgnoreCase))
        {
            await payPalApiClient.ActivateSubscriptionAsync(
                subscription.ProviderSubscriptionId,
                "User requested reactivation",
                cancellationToken);
        }

        return new ProviderAutoRenewRestoreResult
        {
            CanUpdateBilling = true,
            ProviderCode = "paypal",
        };
    }

    public async Task ProcessPayPalWebhookAsync(
        string eventId,
        string eventType,
        string rawBody,
        CancellationToken cancellationToken = default)
    {
        if (await dbContext.ProviderWebhookEvents.AnyAsync(
                e => e.ProviderCode == "paypal" && e.EventId == eventId,
                cancellationToken))
        {
            return;
        }

        dbContext.ProviderWebhookEvents.Add(new ProviderWebhookEvent
        {
            ProviderWebhookEventId = Guid.NewGuid(),
            ProviderCode = "paypal",
            EventId = eventId,
            EventType = eventType,
            ProcessedAt = DateTime.UtcNow,
        });

        using var doc = JsonDocument.Parse(rawBody);
        var root = doc.RootElement;
        if (!root.TryGetProperty("resource", out var resource))
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        switch (eventType)
        {
            case "BILLING.SUBSCRIPTION.ACTIVATED":
            case "PAYMENT.SALE.COMPLETED":
                await HandlePayPalRenewalAsync(resource, cancellationToken);
                break;
            case "BILLING.SUBSCRIPTION.CANCELLED":
            case "BILLING.SUBSCRIPTION.SUSPENDED":
                await HandlePayPalSubscriptionEndedAsync(resource, cancellationToken);
                break;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task ProcessGooglePlayPubSubAsync(
        string rawBody,
        CancellationToken cancellationToken = default) =>
        mobileStoreWebhooks.ProcessGooglePlayPubSubAsync(rawBody, cancellationToken);

    public Task ProcessAppleStoreNotificationAsync(
        string rawBody,
        CancellationToken cancellationToken = default) =>
        mobileStoreWebhooks.ProcessAppleNotificationAsync(rawBody, cancellationToken);

    public async Task<VerifyMobilePurchaseResponse> VerifyMobilePurchaseAsync(
        Guid userId,
        VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken = default)
    {
        var platform = request.Platform.Trim().ToLowerInvariant();
        if (platform is not ("google_play" or "app_store"))
        {
            throw new AppException("Platform must be google_play or app_store.", 400);
        }

        var resolver = new StoreProductResolver(options.Value);
        var (planCode, billingCycle) = resolver.Resolve(request.ProductId);
        var plan = await GetPaidPlanAsync(planCode, cancellationToken);

        MobileStoreSubscriptionDetails storeDetails;
        if (options.Value.UseMockPayments)
        {
            var now = DateTime.UtcNow;
            storeDetails = new MobileStoreSubscriptionDetails
            {
                PlanCode = planCode,
                BillingCycle = billingCycle,
                ProviderSubscriptionId = request.TransactionId ?? request.PurchaseToken,
                IsActive = true,
                AutoRenewEnabled = true,
                PeriodEnd = SubscriptionPeriodCalculator.CalculatePeriodEnd(now, billingCycle),
                LatestTransactionId = request.TransactionId ?? request.PurchaseToken,
            };
        }
        else if (platform == "google_play")
        {
            storeDetails = await mobileStoreVerifier.VerifyGooglePlayAsync(
                request.ProductId,
                request.PurchaseToken,
                cancellationToken);
        }
        else
        {
            storeDetails = await mobileStoreVerifier.VerifyAppStoreAsync(
                request.ProductId,
                request.PurchaseToken,
                request.TransactionId,
                cancellationToken);
        }

        if (!storeDetails.IsActive)
        {
            throw new AppException("Store subscription is not active.", 400, "STORE_SUBSCRIPTION_INACTIVE");
        }

        var providerCode = platform;
        var providerSubscriptionId = storeDetails.ProviderSubscriptionId;
        var paymentTransactionId = storeDetails.LatestTransactionId
            ?? request.TransactionId
            ?? request.PurchaseToken;

        var existingPurchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == providerCode
                     && p.ProviderTransactionId == paymentTransactionId,
                cancellationToken);

        if (existingPurchase is { Status: "validated" })
        {
            var active = await dbContext.UserSubscriptions
                .Include(s => s.Plan)
                .Where(s => s.UserId == userId && s.Status == SubscriptionStatuses.Active)
                .OrderByDescending(s => s.StartedAt)
                .FirstAsync(cancellationToken);

            return new VerifyMobilePurchaseResponse
            {
                PlanCode = active.Plan.Code,
                Status = existingPurchase.Status,
                BillingCycle = active.BillingCycle,
                CurrentPeriodEnd = active.EndsAt,
                AutoRenewEnabled = active.AutoRenewEnabled,
                MockMode = options.Value.UseMockPayments,
            };
        }

        var amount = billingCycle == BillingCycles.Annual
            ? plan.AnnualPrice ?? plan.MonthlyPrice
            : plan.MonthlyPrice;

        var purchase = existingPurchase ?? new Purchase
        {
            PurchaseId = Guid.NewGuid(),
            UserId = userId,
            ProductCode = plan.Code,
            ProductType = "subscription",
            ProviderCode = providerCode,
            ProviderTransactionId = paymentTransactionId,
            Amount = amount,
            CurrencyCode = options.Value.CurrencyCode,
            Status = "pending",
            BillingCycle = storeDetails.BillingCycle,
            CreatedAt = DateTime.UtcNow,
        };

        if (existingPurchase is null)
        {
            dbContext.Purchases.Add(purchase);
        }

        await CompletePurchaseAsync(purchase, cancellationToken);

        var periodStart = DateTime.UtcNow;
        var periodEnd = storeDetails.PeriodEnd
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(
                periodStart,
                storeDetails.BillingCycle);

        var hasActiveSameProvider = await dbContext.UserSubscriptions.AnyAsync(
            s => s.UserId == userId
                 && s.Status == SubscriptionStatuses.Active
                 && s.ProviderCode == providerCode
                 && s.ProviderSubscriptionId == providerSubscriptionId,
            cancellationToken);

        if (hasActiveSameProvider)
        {
            await billingService.RenewSubscriptionPeriodAsync(
                providerSubscriptionId,
                providerCode,
                periodEnd,
                paymentTransactionId,
                cancellationToken);
        }
        else
        {
            await billingService.ActivatePlanAsync(
                userId,
                plan.Code,
                providerCode,
                providerSubscriptionId,
                new SubscriptionActivationOptions
                {
                    BillingCycle = storeDetails.BillingCycle,
                    AutoRenewEnabled = storeDetails.AutoRenewEnabled,
                    PeriodStart = periodStart,
                    PeriodEnd = periodEnd,
                    LastPaymentAt = periodStart,
                },
                cancellationToken);
        }

        return new VerifyMobilePurchaseResponse
        {
            PlanCode = plan.Code,
            Status = "validated",
            BillingCycle = storeDetails.BillingCycle,
            CurrentPeriodEnd = periodEnd,
            AutoRenewEnabled = storeDetails.AutoRenewEnabled,
            MockMode = options.Value.UseMockPayments,
        };
    }

    private async Task<Plan> GetPaidPlanAsync(string planCode, CancellationToken cancellationToken)
    {
        if (!PaidPlanCodes.Contains(planCode))
        {
            throw new AppException("Only paid plans can be purchased.", 400);
        }

        return await dbContext.Plans
            .FirstOrDefaultAsync(p => p.Code == planCode && p.IsActive, cancellationToken)
            ?? throw new AppException($"Plan '{planCode}' is not available.", 400);
    }

    private static int GetPlanRank(string planCode) =>
        planCode.ToLowerInvariant() switch
        {
            "free" => 0,
            "pro" => 1,
            "teacher" => 2,
            "institution" => 3,
            _ => 0,
        };

    private static decimal ResolvePrice(Plan plan, string billingCycle) =>
        billingCycle.Equals("annual", StringComparison.OrdinalIgnoreCase)
            ? plan.AnnualPrice ?? plan.MonthlyPrice ?? 0
            : plan.MonthlyPrice ?? 0;

    private string ResolvePayPalPlanId(string planCode, string billingCycle)
    {
        if (!options.Value.PlanProducts.TryGetValue(planCode, out var mapping))
        {
            return string.Empty;
        }

        return billingCycle == BillingCycles.Annual
            ? mapping.PayPalAnnualPlanId
            : mapping.PayPalMonthlyPlanId;
    }

    private async Task<string> ResolveBillingCycleFromPurchaseAsync(
        Purchase purchase,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(purchase.BillingCycle))
        {
            return SubscriptionPeriodCalculator.NormalizeBillingCycle(purchase.BillingCycle);
        }

        var subscription = await dbContext.UserSubscriptions
            .AsNoTracking()
            .Where(s => s.UserId == purchase.UserId
                        && s.ProviderSubscriptionId == purchase.ProviderTransactionId)
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is not null)
        {
            return subscription.BillingCycle;
        }

        if (purchase.Amount > 0)
        {
            var plan = await dbContext.Plans
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Code == purchase.ProductCode, cancellationToken);
            if (plan?.AnnualPrice is not null && purchase.Amount == plan.AnnualPrice)
            {
                return BillingCycles.Annual;
            }
        }

        return BillingCycles.Monthly;
    }

    private async Task HandlePayPalRenewalAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var subscriptionId = resource.TryGetProperty("billing_agreement_id", out var agreementEl)
            ? agreementEl.GetString()
            : resource.TryGetProperty("id", out var idEl)
                ? idEl.GetString()
                : null;

        if (string.IsNullOrWhiteSpace(subscriptionId))
        {
            return;
        }

        var paymentId = resource.TryGetProperty("id", out var paymentEl)
            ? paymentEl.GetString()
            : null;

        DateTime? periodEnd = null;
        if (resource.TryGetProperty("billing_info", out var billingInfo)
            && billingInfo.TryGetProperty("next_billing_time", out var nextEl))
        {
            var raw = nextEl.GetString();
            if (DateTime.TryParse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind, out var parsed))
            {
                periodEnd = parsed.ToUniversalTime();
            }
        }

        await billingService.RenewSubscriptionPeriodAsync(
            subscriptionId,
            "paypal",
            periodEnd,
            paymentId,
            cancellationToken);
    }

    private async Task HandlePayPalSubscriptionEndedAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var subscriptionId = resource.TryGetProperty("id", out var idEl)
            ? idEl.GetString()
            : null;

        if (string.IsNullOrWhiteSpace(subscriptionId))
        {
            return;
        }

        var subscription = await dbContext.UserSubscriptions
            .Where(s => s.ProviderSubscriptionId == subscriptionId
                        && s.ProviderCode == "paypal"
                        && s.Status == "active")
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription is null)
        {
            return;
        }

        subscription.AutoRenewEnabled = false;
        subscription.CancelAtPeriodEnd = true;
    }

    private async Task CreatePurchaseAsync(
        Guid purchaseId,
        Guid userId,
        string planCode,
        string providerCode,
        string providerTransactionId,
        decimal amount,
        string status,
        DateTime createdAt,
        CancellationToken cancellationToken,
        string? billingCycle = null)
    {
        dbContext.Purchases.Add(new Purchase
        {
            PurchaseId = purchaseId,
            UserId = userId,
            ProductCode = planCode,
            ProductType = "subscription",
            ProviderCode = providerCode,
            ProviderTransactionId = providerTransactionId,
            Amount = amount,
            CurrencyCode = options.Value.CurrencyCode,
            Status = status,
            BillingCycle = billingCycle,
            CreatedAt = createdAt,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task CompletePurchaseAsync(Purchase purchase, CancellationToken cancellationToken)
    {
        purchase.Status = "validated";
        purchase.PurchasedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<PayPalCaptureOrderResponse> BuildValidatedCaptureResponseAsync(
        Guid userId,
        Purchase purchase,
        string providerTransactionId,
        CancellationToken cancellationToken)
    {
        await EnsurePaidPlanActiveForPurchaseAsync(
            userId,
            purchase,
            providerTransactionId,
            autoRenewEnabled: false,
            cancellationToken);

        return new PayPalCaptureOrderResponse
        {
            PlanCode = purchase.ProductCode,
            Status = purchase.Status,
            MockMode = options.Value.UseMockPayments,
        };
    }

    private async Task<PayPalActivateSubscriptionResponse> BuildValidatedSubscriptionActivationResponseAsync(
        Guid userId,
        Purchase purchase,
        string subscriptionId,
        string? billingCycleOverride,
        CancellationToken cancellationToken)
    {
        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(
            billingCycleOverride
            ?? purchase.BillingCycle
            ?? await ResolveBillingCycleFromPurchaseAsync(purchase, cancellationToken));

        DateTime? periodEnd = null;
        if (!options.Value.UseMockPayments)
        {
            var details = await payPalApiClient.GetSubscriptionAsync(
                subscriptionId,
                cancellationToken);
            periodEnd = details.NextBillingTime;
        }

        var active = await EnsurePaidPlanActiveForPurchaseAsync(
            userId,
            purchase,
            subscriptionId,
            autoRenewEnabled: true,
            cancellationToken,
            billingCycle,
            periodEnd);

        return new PayPalActivateSubscriptionResponse
        {
            PlanCode = purchase.ProductCode,
            Status = purchase.Status,
            CurrentPeriodEnd = active.EndsAt ?? periodEnd,
            AutoRenewEnabled = active.AutoRenewEnabled,
            MockMode = options.Value.UseMockPayments,
        };
    }

    private async Task<UserSubscription> EnsurePaidPlanActiveForPurchaseAsync(
        Guid userId,
        Purchase purchase,
        string providerTransactionId,
        bool autoRenewEnabled,
        CancellationToken cancellationToken,
        string? billingCycle = null,
        DateTime? periodEnd = null)
    {
        var active = await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (active is not null
            && string.Equals(active.Plan.Code, purchase.ProductCode, StringComparison.OrdinalIgnoreCase))
        {
            return active;
        }

        var normalizedCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(
            billingCycle
            ?? purchase.BillingCycle
            ?? BillingCycles.Monthly);
        var now = DateTime.UtcNow;
        periodEnd ??= SubscriptionPeriodCalculator.CalculatePeriodEnd(now, normalizedCycle);

        await billingService.ActivatePlanAsync(
            userId,
            purchase.ProductCode,
            "paypal",
            providerTransactionId,
            new SubscriptionActivationOptions
            {
                BillingCycle = normalizedCycle,
                AutoRenewEnabled = autoRenewEnabled,
                PeriodStart = now,
                PeriodEnd = periodEnd,
                LastPaymentAt = purchase.PurchasedAt ?? now,
            },
            cancellationToken);

        return await dbContext.UserSubscriptions
            .Include(s => s.Plan)
            .Where(s => s.UserId == userId && s.Status == "active")
            .OrderByDescending(s => s.StartedAt)
            .FirstAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AiCreditPackDto>> GetAiCreditPacksAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanPurchaseAiCreditPacksAsync(userId, cancellationToken);
        return MapAiCreditPacks(options.Value);
    }

    public async Task<PayPalCreateOrderResponse> CreatePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCreateAiCreditOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanPurchaseAiCreditPacksAsync(userId, cancellationToken);
        var pack = GetAiCreditPackDefinition(request.PackCode);
        var purchaseId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var currency = options.Value.CurrencyCode;

        if (options.Value.UseMockPayments)
        {
            var mockOrderId = $"MOCK-AI-{purchaseId:N}";
            await CreateAiCreditPurchaseAsync(
                purchaseId,
                userId,
                pack.Code,
                "paypal",
                mockOrderId,
                pack.PriceUsd,
                "pending",
                now,
                cancellationToken);

            return new PayPalCreateOrderResponse
            {
                PurchaseId = purchaseId,
                OrderId = mockOrderId,
                ApprovalUrl = null,
                MockMode = true,
            };
        }

        var (orderId, approvalUrl) = await payPalApiClient.CreateOrderAsync(
            pack.PriceUsd,
            currency,
            $"CraftQuest · {pack.Name}",
            cancellationToken);

        await CreateAiCreditPurchaseAsync(
            purchaseId,
            userId,
            pack.Code,
            "paypal",
            orderId,
            pack.PriceUsd,
            "pending",
            now,
            cancellationToken);

        return new PayPalCreateOrderResponse
        {
            PurchaseId = purchaseId,
            OrderId = orderId,
            ApprovalUrl = approvalUrl,
            MockMode = false,
        };
    }

    public async Task<PayPalCaptureAiCreditOrderResponse> CapturePayPalAiCreditOrderAsync(
        Guid userId,
        PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var purchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.UserId == userId
                    && p.ProviderCode == "paypal"
                    && p.ProviderTransactionId == request.OrderId
                    && p.ProductType == "ai_credits",
                cancellationToken)
            ?? throw new AppException("AI credits PayPal purchase not found.", 404);

        if (purchase.Status == "validated")
        {
            var pack = GetAiCreditPackDefinition(purchase.ProductCode);
            var balance = await billingService.GetMyBillingAsync(userId, cancellationToken);
            return new PayPalCaptureAiCreditOrderResponse
            {
                PackCode = pack.Code,
                CreditsGranted = pack.Credits,
                AiCreditsBalance = balance.Credits.AiCredits,
                Status = purchase.Status,
                MockMode = options.Value.UseMockPayments,
            };
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        await CompletePurchaseAsync(purchase, cancellationToken);
        var grantedPack = GetAiCreditPackDefinition(purchase.ProductCode);
        var newBalance = await billingService.GrantPurchasedAiCreditsAsync(
            userId,
            grantedPack.Credits,
            purchase.PurchaseId,
            cancellationToken);

        return new PayPalCaptureAiCreditOrderResponse
        {
            PackCode = grantedPack.Code,
            CreditsGranted = grantedPack.Credits,
            AiCreditsBalance = newBalance,
            Status = "validated",
            MockMode = options.Value.UseMockPayments,
        };
    }

    public async Task<VerifyMobileAiCreditPurchaseResponse> VerifyMobileAiCreditPurchaseAsync(
        Guid userId,
        VerifyMobileAiCreditPurchaseRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanPurchaseAiCreditPacksAsync(userId, cancellationToken);

        var platform = request.Platform.Trim().ToLowerInvariant();
        if (platform is not ("google_play" or "app_store"))
        {
            throw new AppException("Platform must be google_play or app_store.", 400);
        }

        var pack = ResolveAiCreditPackByProductId(request.ProductId);
        var paymentTransactionId = request.TransactionId ?? request.PurchaseToken;

        var existingPurchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == platform
                    && p.ProviderTransactionId == paymentTransactionId,
                cancellationToken);

        if (existingPurchase is { Status: "validated", ProductType: "ai_credits" })
        {
            var balance = await billingService.GetMyBillingAsync(userId, cancellationToken);
            return new VerifyMobileAiCreditPurchaseResponse
            {
                PackCode = existingPurchase.ProductCode,
                CreditsGranted = pack.Credits,
                AiCreditsBalance = balance.Credits.AiCredits,
                Status = existingPurchase.Status,
                MockMode = options.Value.UseMockPayments,
            };
        }

        if (!options.Value.UseMockPayments)
        {
            throw new AppException(
                "Mobile AI credit pack verification requires store configuration or mock payments.",
                501,
                "AI_CREDIT_MOBILE_VERIFY_NOT_CONFIGURED");
        }

        var purchase = existingPurchase ?? new Purchase
        {
            PurchaseId = Guid.NewGuid(),
            UserId = userId,
            ProductCode = pack.Code,
            ProductType = "ai_credits",
            ProviderCode = platform,
            ProviderTransactionId = paymentTransactionId,
            Amount = pack.PriceUsd,
            CurrencyCode = options.Value.CurrencyCode,
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
        };

        if (existingPurchase is null)
        {
            dbContext.Purchases.Add(purchase);
        }

        await CompletePurchaseAsync(purchase, cancellationToken);
        var newBalance = await billingService.GrantPurchasedAiCreditsAsync(
            userId,
            pack.Credits,
            purchase.PurchaseId,
            cancellationToken);

        return new VerifyMobileAiCreditPurchaseResponse
        {
            PackCode = pack.Code,
            CreditsGranted = pack.Credits,
            AiCreditsBalance = newBalance,
            Status = "validated",
            MockMode = true,
        };
    }

    private async Task EnsureCanPurchaseAiCreditPacksAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var billing = await billingService.GetMyBillingAsync(userId, cancellationToken);
        if (billing.Plan.Code.Equals("free", StringComparison.OrdinalIgnoreCase))
        {
            throw new AppException(
                "AI credit packs are not available on the Free plan. Upgrade to Pro or Teacher first.",
                403,
                "AI_CREDIT_PACKS_NOT_AVAILABLE");
        }
    }

    private AiCreditPackDefinition GetAiCreditPackDefinition(string packCode)
    {
        var pack = options.Value.AiCreditPacks
            .FirstOrDefault(p => p.Code.Equals(packCode, StringComparison.OrdinalIgnoreCase));

        return pack ?? throw new AppException($"AI credit pack '{packCode}' is not available.", 400);
    }

    private AiCreditPackDefinition ResolveAiCreditPackByProductId(string productId)
    {
        var pack = options.Value.AiCreditPacks.FirstOrDefault(p =>
            (!string.IsNullOrWhiteSpace(p.GooglePlayProductId)
                && p.GooglePlayProductId.Equals(productId, StringComparison.OrdinalIgnoreCase))
            || (!string.IsNullOrWhiteSpace(p.AppStoreProductId)
                && p.AppStoreProductId.Equals(productId, StringComparison.OrdinalIgnoreCase)));

        return pack ?? throw new AppException($"Unknown AI credit pack product id '{productId}'.", 400);
    }

    private static IReadOnlyList<AiCreditPackDto> MapAiCreditPacks(PaymentOptions paymentOptions) =>
        paymentOptions.AiCreditPacks
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Credits)
            .Select(p => new AiCreditPackDto
            {
                Code = p.Code,
                Name = p.Name,
                Credits = p.Credits,
                Price = p.PriceUsd,
                CurrencyCode = paymentOptions.CurrencyCode,
                GooglePlayProductId = string.IsNullOrWhiteSpace(p.GooglePlayProductId)
                    ? null
                    : p.GooglePlayProductId,
                AppStoreProductId = string.IsNullOrWhiteSpace(p.AppStoreProductId)
                    ? null
                    : p.AppStoreProductId,
            })
            .ToList();

    private async Task CreateAiCreditPurchaseAsync(
        Guid purchaseId,
        Guid userId,
        string packCode,
        string providerCode,
        string providerTransactionId,
        decimal amount,
        string status,
        DateTime createdAt,
        CancellationToken cancellationToken)
    {
        dbContext.Purchases.Add(new Purchase
        {
            PurchaseId = purchaseId,
            UserId = userId,
            ProductCode = packCode,
            ProductType = "ai_credits",
            ProviderCode = providerCode,
            ProviderTransactionId = providerTransactionId,
            Amount = amount,
            CurrencyCode = options.Value.CurrencyCode,
            Status = status,
            CreatedAt = createdAt,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
    }

}
