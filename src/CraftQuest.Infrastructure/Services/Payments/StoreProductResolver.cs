using CraftQuest.Application.Exceptions;
using CraftQuest.Application.Options;
using CraftQuest.Domain.Constants;

namespace CraftQuest.Infrastructure.Services.Payments;

internal sealed class StoreProductResolver(PaymentOptions options)
{
    public (string PlanCode, string BillingCycle) Resolve(string productId)
    {
        foreach (var (planCode, mapping) in options.PlanProducts)
        {
            if (Matches(mapping.GooglePlayProductId, productId)
                || Matches(mapping.AppStoreProductId, productId))
            {
                return (planCode, BillingCycles.Monthly);
            }

            if (Matches(mapping.GooglePlayAnnualProductId, productId)
                || Matches(mapping.AppStoreAnnualProductId, productId))
            {
                return (planCode, BillingCycles.Annual);
            }
        }

        throw new AppException($"Unknown store product id '{productId}'.", 400);
    }

    private static bool Matches(string? configured, string productId) =>
        !string.IsNullOrWhiteSpace(configured)
        && string.Equals(configured, productId, StringComparison.OrdinalIgnoreCase);
}
