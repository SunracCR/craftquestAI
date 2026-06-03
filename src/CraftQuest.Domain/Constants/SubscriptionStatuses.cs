namespace CraftQuest.Domain.Constants;

public static class SubscriptionStatuses
{
    public const string Active = "active";
    public const string Expired = "expired";
    public const string Cancelled = "cancelled";
    public const string PastDue = "past_due";
    public const string Trial = "trial";
}

public static class BillingCycles
{
    public const string Monthly = "monthly";
    public const string Annual = "annual";
}
