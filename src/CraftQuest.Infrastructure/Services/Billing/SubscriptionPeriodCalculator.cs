namespace CraftQuest.Infrastructure.Services.Billing;

internal static class SubscriptionPeriodCalculator
{
    public static string NormalizeBillingCycle(string? billingCycle) =>
        billingCycle?.Equals("annual", StringComparison.OrdinalIgnoreCase) == true
            ? "annual"
            : "monthly";

    public static DateTime CalculatePeriodEnd(DateTime periodStart, string billingCycle) =>
        NormalizeBillingCycle(billingCycle) == "annual"
            ? periodStart.AddYears(1)
            : periodStart.AddMonths(1);

    public static bool IsRecurringProvider(string? providerCode) =>
        !string.IsNullOrWhiteSpace(providerCode)
        && providerCode is not ("internal" or "manual_admin" or "manual_test");

    public static bool IsMobileStoreProvider(string? providerCode) =>
        providerCode is "google_play" or "app_store";
}
