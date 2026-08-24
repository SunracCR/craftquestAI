using System.Text.Json;
using CraftQuest.Application.Billing;
using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services.Billing;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public class PaymentService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    PayPalApiClient payPalApiClient,
    IMobileStoreSubscriptionVerifier mobileStoreVerifier,
    IMobileStoreProductVerifier mobileProductVerifier,
    MobileStoreWebhookProcessor mobileStoreWebhooks,
    IPrepPlusPaymentService prepPlusPaymentService,
    IOptions<PaymentOptions> options,
    ILogger<PaymentService> logger) : IPaymentService
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
            PurchaseStatuses.AwaitingPayment,
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

        if (purchase.Status == PurchaseStatuses.Validated)
        {
            return await BuildValidatedCaptureResponseAsync(
                userId,
                purchase,
                request.OrderId,
                cancellationToken);
        }

        if (!PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            throw new AppException(
                $"PayPal purchase cannot be captured in status '{purchase.Status}'.",
                409,
                "PURCHASE_NOT_CAPTURABLE");
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        var billingCycle = await ResolveBillingCycleFromPurchaseAsync(purchase, cancellationToken);
        var now = DateTime.UtcNow;
        await ExecuteInTransactionAsync(async () =>
        {
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
            await dbContext.SaveChangesAsync(cancellationToken);
        }, cancellationToken);

        return new PayPalCaptureOrderResponse
        {
            PlanCode = purchase.ProductCode,
            Status = PurchaseStatuses.Validated,
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
            PurchaseStatuses.AwaitingPayment,
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

        if (purchase.Status == PurchaseStatuses.Validated)
        {
            return await BuildValidatedSubscriptionActivationResponseAsync(
                userId,
                purchase,
                request.SubscriptionId,
                request.BillingCycle,
                cancellationToken);
        }

        if (!PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            throw new AppException(
                $"PayPal subscription cannot be activated in status '{purchase.Status}'.",
                409,
                "PURCHASE_NOT_ACTIVATABLE");
        }

        var billingCycle = SubscriptionPeriodCalculator.NormalizeBillingCycle(
            request.BillingCycle
            ?? purchase.BillingCycle
            ?? await ResolveBillingCycleFromPurchaseAsync(purchase, cancellationToken));
        DateTime? periodEnd = null;

        if (!options.Value.UseMockPayments)
        {
            var details = await WaitForActivePayPalSubscriptionAsync(
                request.SubscriptionId,
                cancellationToken);
            periodEnd = details.NextBillingTime;
        }

        var now = DateTime.UtcNow;
        periodEnd ??= SubscriptionPeriodCalculator.CalculatePeriodEnd(now, billingCycle);

        await ExecuteInTransactionAsync(async () =>
        {
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
            await dbContext.SaveChangesAsync(cancellationToken);
        }, cancellationToken);

        return new PayPalActivateSubscriptionResponse
        {
            PlanCode = purchase.ProductCode,
            Status = PurchaseStatuses.Validated,
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
        using var doc = JsonDocument.Parse(rawBody);
        var root = doc.RootElement;

        if (root.TryGetProperty("id", out var webhookIdEl))
        {
            var webhookId = webhookIdEl.GetString();
            if (!string.IsNullOrWhiteSpace(webhookId))
            {
                eventId = webhookId;
            }
        }

        if (root.TryGetProperty("event_type", out var eventTypeEl))
        {
            var parsedEventType = eventTypeEl.GetString();
            if (!string.IsNullOrWhiteSpace(parsedEventType))
            {
                eventType = parsedEventType;
            }
        }

        if (await dbContext.ProviderWebhookEvents.AnyAsync(
                e => e.ProviderCode == "paypal" && e.EventId == eventId,
                cancellationToken))
        {
            return;
        }

        if (!root.TryGetProperty("resource", out var resource))
        {
            dbContext.ProviderWebhookEvents.Add(new ProviderWebhookEvent
            {
                ProviderWebhookEventId = Guid.NewGuid(),
                ProviderCode = "paypal",
                EventId = eventId,
                EventType = eventType,
                ProcessedAt = DateTime.UtcNow,
            });
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        switch (eventType)
        {
            case "BILLING.SUBSCRIPTION.ACTIVATED":
                await HandlePayPalSubscriptionActivatedAsync(resource, cancellationToken);
                break;
            case "PAYMENT.SALE.COMPLETED":
                await HandlePayPalSubscriptionPaymentAsync(resource, cancellationToken);
                break;
            case "CHECKOUT.ORDER.COMPLETED":
            case "PAYMENT.CAPTURE.COMPLETED":
                await HandlePayPalOrderCapturedAsync(resource, cancellationToken);
                break;
            case "PAYMENT.CAPTURE.DENIED":
            case "PAYMENT.CAPTURE.DECLINED":
                await HandlePayPalCaptureDeniedAsync(resource, cancellationToken);
                break;
            case "PAYMENT.CAPTURE.REFUNDED":
            case "PAYMENT.SALE.REFUNDED":
                await HandlePayPalRefundAsync(resource, cancellationToken);
                break;
            case "BILLING.SUBSCRIPTION.PAYMENT.FAILED":
                await HandlePayPalSubscriptionPaymentFailedAsync(resource, cancellationToken);
                break;
            case "BILLING.SUBSCRIPTION.CANCELLED":
            case "BILLING.SUBSCRIPTION.SUSPENDED":
                await HandlePayPalSubscriptionEndedAsync(resource, cancellationToken);
                break;
        }

        dbContext.ProviderWebhookEvents.Add(new ProviderWebhookEvent
        {
            ProviderWebhookEventId = Guid.NewGuid(),
            ProviderCode = "paypal",
            EventId = eventId,
            EventType = eventType,
            ProcessedAt = DateTime.UtcNow,
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        logger.LogInformation(
            "Processed PayPal webhook {EventType} event {EventId}",
            eventType,
            eventId);
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

        EnsurePurchaseOwnership(existingPurchase, userId);

        if (existingPurchase is { Status: var status }
            && string.Equals(status, PurchaseStatuses.Validated, StringComparison.OrdinalIgnoreCase))
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

        var periodStart = DateTime.UtcNow;
        var periodEnd = storeDetails.PeriodEnd
            ?? SubscriptionPeriodCalculator.CalculatePeriodEnd(
                periodStart,
                storeDetails.BillingCycle);

        await ExecuteInTransactionAsync(async () =>
        {
            if (existingPurchase is null)
            {
                dbContext.Purchases.Add(purchase);
            }

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

            await CompletePurchaseAsync(purchase, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
        }, cancellationToken);

        logger.LogInformation(
            "Validated mobile subscription purchase for user {UserId} plan {PlanCode} transaction {TransactionId}",
            userId,
            plan.Code,
            paymentTransactionId);

        return new VerifyMobilePurchaseResponse
        {
            PlanCode = plan.Code,
            Status = PurchaseStatuses.Validated,
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

    private async Task HandlePayPalSubscriptionActivatedAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var subscriptionId = ReadPayPalResourceId(resource);
        if (string.IsNullOrWhiteSpace(subscriptionId))
        {
            return;
        }

        await TryActivatePendingPayPalSubscriptionAsync(subscriptionId, cancellationToken);
    }

    private async Task HandlePayPalSubscriptionPaymentAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var subscriptionId = resource.TryGetProperty("billing_agreement_id", out var agreementEl)
            ? agreementEl.GetString()
            : ReadPayPalResourceId(resource);

        if (string.IsNullOrWhiteSpace(subscriptionId))
        {
            return;
        }

        var paymentId = ReadPayPalResourceId(resource);
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

        try
        {
            await billingService.RenewSubscriptionPeriodAsync(
                subscriptionId,
                "paypal",
                periodEnd,
                paymentId,
                cancellationToken);
        }
        catch (AppException ex) when (ex.StatusCode == 404)
        {
            await TryActivatePendingPayPalSubscriptionAsync(subscriptionId, cancellationToken);
        }
    }

    private async Task HandlePayPalOrderCapturedAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var orderId = ResolvePayPalOrderIdFromResource(resource);
        if (string.IsNullOrWhiteSpace(orderId))
        {
            return;
        }

        await TryFulfillPendingPayPalOrderAsync(orderId, cancellationToken);
    }

    private async Task TryActivatePendingPayPalSubscriptionAsync(
        string subscriptionId,
        CancellationToken cancellationToken)
    {
        var purchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == "paypal"
                    && p.ProviderTransactionId == subscriptionId
                    && (p.Status == PurchaseStatuses.Pending
                        || p.Status == PurchaseStatuses.AwaitingPayment),
                cancellationToken);

        if (purchase is null)
        {
            return;
        }

        await ActivatePayPalSubscriptionAsync(
            purchase.UserId,
            new PayPalActivateSubscriptionRequest
            {
                SubscriptionId = subscriptionId,
                BillingCycle = purchase.BillingCycle,
            },
            cancellationToken);
    }

    private async Task TryFulfillPendingPayPalOrderAsync(
        string orderId,
        CancellationToken cancellationToken)
    {
        var purchase = await dbContext.Purchases
            .AsNoTracking()
            .FirstOrDefaultAsync(
                p => p.ProviderCode == "paypal"
                    && p.ProviderTransactionId == orderId,
                cancellationToken);

        if (purchase is null || purchase.Status == PurchaseStatuses.Validated)
        {
            return;
        }

        if (!PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            return;
        }

        if (purchase.ProductType == "prep_access")
        {
            await prepPlusPaymentService.CapturePayPalOrderAsync(
                purchase.UserId,
                new PayPalCaptureOrderRequest { OrderId = orderId },
                cancellationToken);
            return;
        }

        if (purchase.ProductType == "ai_credits")
        {
            await CapturePayPalAiCreditOrderAsync(
                purchase.UserId,
                new PayPalCaptureOrderRequest { OrderId = orderId },
                cancellationToken);
            return;
        }

        await CapturePayPalOrderAsync(
            purchase.UserId,
            new PayPalCaptureOrderRequest { OrderId = orderId },
            cancellationToken);
    }

    private static string? ReadPayPalResourceId(JsonElement resource) =>
        resource.TryGetProperty("id", out var idEl) ? idEl.GetString() : null;

    private static string? ResolvePayPalOrderIdFromResource(JsonElement resource)
    {
        if (resource.TryGetProperty("supplementary_data", out var supplementary)
            && supplementary.TryGetProperty("related_ids", out var relatedIds)
            && relatedIds.TryGetProperty("order_id", out var orderIdEl))
        {
            var orderId = orderIdEl.GetString();
            if (!string.IsNullOrWhiteSpace(orderId))
            {
                return orderId;
            }
        }

        return ReadPayPalResourceId(resource);
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
        purchase.Status = PurchaseStatuses.Validated;
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
            PurchaseStatuses.AwaitingPayment,
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

        if (purchase.Status == PurchaseStatuses.Validated)
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

        if (!PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            throw new AppException(
                $"AI credits PayPal purchase cannot be captured in status '{purchase.Status}'.",
                409,
                "PURCHASE_NOT_CAPTURABLE");
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        var grantedPack = GetAiCreditPackDefinition(purchase.ProductCode);
        var newBalance = 0;
        await ExecuteInTransactionAsync(async () =>
        {
            newBalance = await billingService.GrantPurchasedAiCreditsAsync(
                userId,
                grantedPack.Credits,
                purchase.PurchaseId,
                cancellationToken);

            await CompletePurchaseAsync(purchase, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
        }, cancellationToken);

        return new PayPalCaptureAiCreditOrderResponse
        {
            PackCode = grantedPack.Code,
            CreditsGranted = grantedPack.Credits,
            AiCreditsBalance = newBalance,
            Status = PurchaseStatuses.Validated,
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

        MobileStoreProductDetails storeDetails;
        if (options.Value.UseMockPayments)
        {
            storeDetails = new MobileStoreProductDetails
            {
                IsValid = true,
                TransactionId = request.TransactionId ?? request.PurchaseToken,
            };
        }
        else if (platform == "google_play")
        {
            storeDetails = await mobileProductVerifier.VerifyGooglePlayConsumableAsync(
                request.ProductId,
                request.PurchaseToken,
                cancellationToken);
        }
        else
        {
            storeDetails = await mobileProductVerifier.VerifyAppStoreConsumableAsync(
                request.ProductId,
                request.PurchaseToken,
                request.TransactionId,
                cancellationToken);
        }

        if (!storeDetails.IsValid)
        {
            throw new AppException(
                "Store product purchase is not valid.",
                400,
                "STORE_PURCHASE_INVALID");
        }

        var paymentTransactionId = storeDetails.TransactionId;

        var existingPurchase = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == platform
                    && p.ProviderTransactionId == paymentTransactionId,
                cancellationToken);

        EnsurePurchaseOwnership(existingPurchase, userId);

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

        var aiCreditsBalance = 0;
        await ExecuteInTransactionAsync(async () =>
        {
            if (existingPurchase is null)
            {
                dbContext.Purchases.Add(purchase);
            }

            aiCreditsBalance = await billingService.GrantPurchasedAiCreditsAsync(
                userId,
                pack.Credits,
                purchase.PurchaseId,
                cancellationToken);

            await CompletePurchaseAsync(purchase, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);

            if (!options.Value.UseMockPayments && platform == "google_play")
            {
                await mobileProductVerifier.ConsumeGooglePlayConsumableAsync(
                    request.ProductId,
                    request.PurchaseToken,
                    cancellationToken);
            }

            logger.LogInformation(
                "Validated mobile AI credit purchase for user {UserId} pack {PackCode} transaction {TransactionId}",
                userId,
                pack.Code,
                paymentTransactionId);
        }, cancellationToken);

        return new VerifyMobileAiCreditPurchaseResponse
        {
            PackCode = pack.Code,
            CreditsGranted = pack.Credits,
            AiCreditsBalance = aiCreditsBalance,
            Status = "validated",
            MockMode = options.Value.UseMockPayments,
        };
    }

    public async Task<int> ReconcilePendingPurchasesAsync(
        CancellationToken cancellationToken = default)
    {
        await ExpireStaleAwaitingPaymentsAsync(cancellationToken);

        var cutoff = DateTime.UtcNow.AddSeconds(-30);
        var openPurchases = await dbContext.Purchases
            .Where(p => (p.Status == PurchaseStatuses.Pending
                         || p.Status == PurchaseStatuses.AwaitingPayment)
                        && p.CreatedAt < cutoff)
            .OrderBy(p => p.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);

        var reconciled = 0;
        foreach (var purchase in openPurchases)
        {
            if (await TryReconcilePendingPurchaseAsync(purchase, cancellationToken))
            {
                reconciled++;
            }
        }

        return reconciled;
    }

    public async Task<ReconcilePendingPurchasesResponse> ReconcileUserPendingPurchasesAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var openPurchases = await dbContext.Purchases
            .Where(p => p.UserId == userId
                        && (p.Status == PurchaseStatuses.Pending
                            || p.Status == PurchaseStatuses.AwaitingPayment))
            .OrderByDescending(p => p.CreatedAt)
            .Take(20)
            .ToListAsync(cancellationToken);

        var fulfilled = 0;
        foreach (var purchase in openPurchases)
        {
            if (await TryReconcilePendingPurchaseAsync(purchase, cancellationToken))
            {
                fulfilled++;
            }
        }

        return new ReconcilePendingPurchasesResponse { FulfilledCount = fulfilled };
    }

    private async Task ExpireStaleAwaitingPaymentsAsync(CancellationToken cancellationToken)
    {
        var cutoff = DateTime.UtcNow.AddHours(-48);
        var stale = await dbContext.Purchases
            .Where(p => p.Status == PurchaseStatuses.AwaitingPayment && p.CreatedAt < cutoff)
            .Take(100)
            .ToListAsync(cancellationToken);

        if (stale.Count == 0)
        {
            return;
        }

        foreach (var purchase in stale)
        {
            purchase.Status = PurchaseStatuses.Cancelled;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<bool> TryReconcilePendingPurchaseAsync(
        Purchase purchase,
        CancellationToken cancellationToken)
    {
        if (!PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            return false;
        }

        try
        {
            if (purchase.ProviderCode == "paypal")
            {
                var transactionId = purchase.ProviderTransactionId;
                if (string.IsNullOrWhiteSpace(transactionId))
                {
                    return false;
                }

                if (purchase.ProductType == "subscription")
                {
                    await TryActivatePendingPayPalSubscriptionAsync(
                        transactionId,
                        cancellationToken);
                }
                else
                {
                    await TryFulfillPendingPayPalOrderAsync(
                        transactionId,
                        cancellationToken);
                }
            }
            else if (purchase.ProviderCode is "google_play" or "app_store")
            {
                if (!await TryReconcileFulfilledMobilePurchaseAsync(purchase, cancellationToken))
                {
                    return false;
                }
            }
            else
            {
                return false;
            }

            await dbContext.Entry(purchase).ReloadAsync(cancellationToken);
            return purchase.Status == PurchaseStatuses.Validated;
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed to reconcile open purchase {PurchaseId} for user {UserId}",
                purchase.PurchaseId,
                purchase.UserId);
            return false;
        }
    }

    private async Task<bool> TryReconcileFulfilledMobilePurchaseAsync(
        Purchase purchase,
        CancellationToken cancellationToken)
    {
        if (purchase.ProductType == "subscription")
        {
            var hasMatchingSubscription = await dbContext.UserSubscriptions.AnyAsync(
                s => s.UserId == purchase.UserId
                     && s.Status == SubscriptionStatuses.Active
                     && s.ProviderCode == purchase.ProviderCode
                     && s.StartedAt >= purchase.CreatedAt.AddMinutes(-5),
                cancellationToken);

            if (!hasMatchingSubscription)
            {
                return false;
            }
        }
        else if (purchase.ProductType == "ai_credits")
        {
            var creditsGranted = await dbContext.CreditLedgerEntries.AnyAsync(
                e => e.UserId == purchase.UserId
                     && e.ReferenceId == purchase.PurchaseId,
                cancellationToken);

            if (!creditsGranted)
            {
                return false;
            }
        }
        else if (purchase.ProductType == "prep_access")
        {
            var accessGranted = await dbContext.QuizAccesses.AnyAsync(
                g => g.GrantedByPurchaseId == purchase.PurchaseId,
                cancellationToken);

            if (!accessGranted)
            {
                return false;
            }
        }
        else
        {
            return false;
        }

        purchase.Status = PurchaseStatuses.Validated;
        purchase.PurchasedAt ??= DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task HandlePayPalCaptureDeniedAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var orderId = ResolvePayPalOrderIdFromResource(resource);
        if (string.IsNullOrWhiteSpace(orderId))
        {
            return;
        }

        var purchase = await dbContext.Purchases.FirstOrDefaultAsync(
            p => p.ProviderCode == "paypal" && p.ProviderTransactionId == orderId,
            cancellationToken);
        if (purchase is null || !PurchaseStatuses.NeedsFulfillment(purchase.Status))
        {
            return;
        }

        logger.LogWarning(
            "PayPal capture denied for pending purchase {PurchaseId} order {OrderId}",
            purchase.PurchaseId,
            orderId);
    }

    private async Task HandlePayPalRefundAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var transactionId = ReadPayPalResourceId(resource);
        if (string.IsNullOrWhiteSpace(transactionId))
        {
            return;
        }

        var purchase = await dbContext.Purchases.FirstOrDefaultAsync(
            p => p.ProviderTransactionId == transactionId,
            cancellationToken);
        if (purchase is null || purchase.Status != "validated")
        {
            return;
        }

        if (purchase.ProductType == "subscription")
        {
            await billingService.RevokeSubscriptionImmediatelyAsync(
                purchase.ProviderTransactionId,
                purchase.ProviderCode,
                cancellationToken);
        }

        logger.LogWarning(
            "PayPal refund received for purchase {PurchaseId} user {UserId}",
            purchase.PurchaseId,
            purchase.UserId);
    }

    private async Task HandlePayPalSubscriptionPaymentFailedAsync(
        JsonElement resource,
        CancellationToken cancellationToken)
    {
        var subscriptionId = ReadPayPalResourceId(resource);
        if (string.IsNullOrWhiteSpace(subscriptionId))
        {
            return;
        }

        var subscription = await dbContext.UserSubscriptions.FirstOrDefaultAsync(
            s => s.ProviderSubscriptionId == subscriptionId && s.ProviderCode == "paypal",
            cancellationToken);
        if (subscription is null)
        {
            return;
        }

        subscription.PaymentIssuePending = true;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static void EnsurePurchaseOwnership(Purchase? purchase, Guid userId)
    {
        if (purchase is not null && purchase.UserId != userId)
        {
            throw new AppException(
                "This store transaction belongs to another account.",
                409,
                "PURCHASE_OWNERSHIP_MISMATCH");
        }
    }

    private async Task<PayPalSubscriptionDetails> WaitForActivePayPalSubscriptionAsync(
        string subscriptionId,
        CancellationToken cancellationToken)
    {
        var retryDelays = new[]
        {
            TimeSpan.Zero,
            TimeSpan.FromSeconds(2),
            TimeSpan.FromSeconds(4),
            TimeSpan.FromSeconds(6),
            TimeSpan.FromSeconds(8),
        };

        PayPalSubscriptionDetails? lastDetails = null;
        foreach (var delay in retryDelays)
        {
            if (delay > TimeSpan.Zero)
            {
                await Task.Delay(delay, cancellationToken);
            }

            lastDetails = await payPalApiClient.GetSubscriptionAsync(
                subscriptionId,
                cancellationToken);

            if (string.Equals(lastDetails.Status, "ACTIVE", StringComparison.OrdinalIgnoreCase))
            {
                return lastDetails;
            }

            if (!IsPayPalSubscriptionAwaitingActivation(lastDetails.Status))
            {
                break;
            }
        }

        throw new AppException(
            $"PayPal subscription is not active yet (status: {lastDetails?.Status ?? "UNKNOWN"}).",
            409,
            "PAYPAL_SUBSCRIPTION_NOT_ACTIVE");
    }

    private static bool IsPayPalSubscriptionAwaitingActivation(string? status) =>
        string.Equals(status, "APPROVAL_PENDING", StringComparison.OrdinalIgnoreCase)
        || string.Equals(status, "APPROVED", StringComparison.OrdinalIgnoreCase);

    private async Task ExecuteInTransactionAsync(
        Func<Task> action,
        CancellationToken cancellationToken)
    {
        if (!dbContext.Database.IsRelational())
        {
            await action();
            return;
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            await action();
            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
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

        return pack ?? throw new AppException(
            $"Unknown AI credit pack product id '{productId}'.",
            400,
            "AI_CREDIT_PACK_UNKNOWN_PRODUCT");
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
