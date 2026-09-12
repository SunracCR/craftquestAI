namespace CraftQuest.Infrastructure.Services.Payments;

internal static class GooglePlaySubscriptionActivationPolicy
{
    public static bool IsActiveForVerification(
        string? subscriptionState,
        DateTime? periodEndUtc,
        DateTime utcNow)
    {
        var state = subscriptionState ?? string.Empty;
        if (state.Equals("SUBSCRIPTION_STATE_ACTIVE", StringComparison.OrdinalIgnoreCase)
            || state.Equals("SUBSCRIPTION_STATE_IN_GRACE_PERIOD", StringComparison.OrdinalIgnoreCase)
            || state.Equals("SUBSCRIPTION_STATE_ON_HOLD", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (state.Equals("SUBSCRIPTION_STATE_PENDING", StringComparison.OrdinalIgnoreCase)
            && periodEndUtc is not null
            && periodEndUtc.Value > utcNow)
        {
            return true;
        }

        return false;
    }
}
