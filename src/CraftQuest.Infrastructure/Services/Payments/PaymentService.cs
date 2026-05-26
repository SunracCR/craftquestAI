using CraftQuest.Application.Contracts;
using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public class PaymentService(
    CraftQuestDbContext dbContext,
    IBillingService billingService,
    PayPalApiClient payPalApiClient,
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

        if (userId.HasValue)
        {
            var billing = await billingService.GetMyBillingAsync(userId.Value, cancellationToken);
            var currentRank = GetPlanRank(billing.Plan.Code);
            plans = plans.Where(p => GetPlanRank(p.Code) > currentRank).ToList();
        }

        return plans.Select(plan =>
        {
            paymentOptions.PlanProducts.TryGetValue(plan.Code, out var mapping);
            return new UpgradeablePlanDto
            {
                Code = plan.Code,
                Name = plan.Name,
                MonthlyPrice = plan.MonthlyPrice,
                AnnualPrice = plan.AnnualPrice,
                GooglePlayProductId = mapping?.GooglePlayProductId,
                AppStoreProductId = mapping?.AppStoreProductId,
            };
        }).ToList();
    }

    public async Task<PayPalCreateOrderResponse> CreatePayPalOrderAsync(
        Guid userId,
        PayPalCreateOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var plan = await GetPaidPlanAsync(request.PlanCode, cancellationToken);
        var amount = ResolvePrice(plan, request.BillingCycle);
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
            cancellationToken);

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

        if (purchase.Status == "validated")
        {
            return new PayPalCaptureOrderResponse
            {
                PlanCode = purchase.ProductCode,
                Status = purchase.Status,
                MockMode = options.Value.UseMockPayments,
            };
        }

        if (!options.Value.UseMockPayments)
        {
            await payPalApiClient.CaptureOrderAsync(request.OrderId, cancellationToken);
        }

        await CompletePurchaseAsync(purchase, cancellationToken);

        await billingService.ActivatePlanAsync(
            userId,
            purchase.ProductCode,
            "paypal",
            request.OrderId,
            cancellationToken);

        return new PayPalCaptureOrderResponse
        {
            PlanCode = purchase.ProductCode,
            Status = "validated",
            MockMode = options.Value.UseMockPayments,
        };
    }

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

        var planCode = ResolvePlanCodeFromProductId(request.ProductId);
        var plan = await GetPaidPlanAsync(planCode, cancellationToken);

        if (!options.Value.UseMockPayments)
        {
            await ValidateStoreReceiptAsync(platform, request, cancellationToken);
        }

        var providerCode = platform == "google_play" ? "google_play" : "app_store";
        var transactionId = request.TransactionId ?? request.PurchaseToken;

        var existing = await dbContext.Purchases
            .FirstOrDefaultAsync(
                p => p.ProviderCode == providerCode &&
                     p.ProviderTransactionId == transactionId,
                cancellationToken);

        if (existing is { Status: "validated" })
        {
            return new VerifyMobilePurchaseResponse
            {
                PlanCode = existing.ProductCode,
                Status = existing.Status,
                MockMode = options.Value.UseMockPayments,
            };
        }

        var purchase = existing ?? new Purchase
        {
            PurchaseId = Guid.NewGuid(),
            UserId = userId,
            ProductCode = plan.Code,
            ProductType = "subscription",
            ProviderCode = providerCode,
            ProviderTransactionId = transactionId,
            Amount = plan.MonthlyPrice,
            CurrencyCode = options.Value.CurrencyCode,
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
        };

        if (existing is null)
        {
            dbContext.Purchases.Add(purchase);
        }

        await CompletePurchaseAsync(purchase, cancellationToken);

        await billingService.ActivatePlanAsync(
            userId,
            plan.Code,
            providerCode,
            transactionId,
            cancellationToken);

        return new VerifyMobilePurchaseResponse
        {
            PlanCode = plan.Code,
            Status = "validated",
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

    private string ResolvePlanCodeFromProductId(string productId)
    {
        foreach (var (planCode, mapping) in options.Value.PlanProducts)
        {
            if (string.Equals(mapping.GooglePlayProductId, productId, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(mapping.AppStoreProductId, productId, StringComparison.OrdinalIgnoreCase))
            {
                return planCode;
            }
        }

        throw new AppException($"Unknown store product id '{productId}'.", 400);
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

    private async Task CreatePurchaseAsync(
        Guid purchaseId,
        Guid userId,
        string planCode,
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
            ProductCode = planCode,
            ProductType = "subscription",
            ProviderCode = providerCode,
            ProviderTransactionId = providerTransactionId,
            Amount = amount,
            CurrencyCode = options.Value.CurrencyCode,
            Status = status,
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

    private Task ValidateStoreReceiptAsync(
        string platform,
        VerifyMobilePurchaseRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PurchaseToken))
        {
            throw new AppException("purchaseToken is required.", 400);
        }

        var mobile = options.Value.Mobile;
        if (platform == "google_play" &&
            string.IsNullOrWhiteSpace(mobile.GooglePlayPackageName))
        {
            throw new AppException("Google Play is not configured.", 503);
        }

        if (platform == "app_store" && string.IsNullOrWhiteSpace(mobile.AppleSharedSecret))
        {
            throw new AppException(
                "App Store verification requires Payments:Mobile:AppleSharedSecret. " +
                "Use UseMockPayments=true for local development.",
                503);
        }

        // Production: integrate Google Play Developer API / App Store Server API here.
        return Task.CompletedTask;
    }
}
