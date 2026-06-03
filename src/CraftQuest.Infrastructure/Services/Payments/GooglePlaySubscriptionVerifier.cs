using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Options;
using Google.Apis.AndroidPublisher.v3;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Services;
using Microsoft.Extensions.Options;

namespace CraftQuest.Infrastructure.Services.Payments;

public sealed class GooglePlaySubscriptionVerifier(IOptions<PaymentOptions> options)
{
    public async Task<MobileStoreSubscriptionDetails> VerifyAsync(
        string productId,
        string purchaseToken,
        CancellationToken cancellationToken)
    {
        var mobile = options.Value.Mobile;
        if (string.IsNullOrWhiteSpace(mobile.GooglePlayPackageName))
        {
            throw new AppException("Google Play package name is not configured.", 503);
        }

        if (string.IsNullOrWhiteSpace(mobile.GooglePlayServiceAccountJsonPath)
            || !File.Exists(mobile.GooglePlayServiceAccountJsonPath))
        {
            throw new AppException(
                "Google Play service account JSON is not configured.",
                503);
        }

        var resolver = new StoreProductResolver(options.Value);
        var (planCode, billingCycle) = resolver.Resolve(productId);

        var credential = GoogleCredential.FromFile(mobile.GooglePlayServiceAccountJsonPath)
            .CreateScoped(AndroidPublisherService.Scope.Androidpublisher);

        var service = new AndroidPublisherService(new BaseClientService.Initializer
        {
            HttpClientInitializer = credential,
            ApplicationName = "CraftQuest",
        });

        var subscription = await service.Purchases.Subscriptionsv2
            .Get(mobile.GooglePlayPackageName, purchaseToken)
            .ExecuteAsync(cancellationToken);

        var state = subscription.SubscriptionState ?? string.Empty;
        var isActive = state.Equals(
            "SUBSCRIPTION_STATE_ACTIVE",
            StringComparison.OrdinalIgnoreCase);

        DateTime? periodEnd = null;
        var lineItem = subscription.LineItems?.FirstOrDefault();
        if (lineItem?.ExpiryTimeDateTimeOffset is not null)
        {
            periodEnd = lineItem.ExpiryTimeDateTimeOffset.Value.UtcDateTime;
        }

        var autoRenew = lineItem?.AutoRenewingPlan?.AutoRenewEnabled ?? true;

        return new MobileStoreSubscriptionDetails
        {
            PlanCode = planCode,
            BillingCycle = billingCycle,
            ProviderSubscriptionId = purchaseToken,
            IsActive = isActive,
            AutoRenewEnabled = autoRenew,
            PeriodEnd = periodEnd,
            LatestTransactionId = subscription.LatestOrderId,
        };
    }
}
