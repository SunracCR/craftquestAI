namespace CraftQuest.Domain.Constants;

public static class ParentalConsentStatuses
{
    public const string NotRequired = "not_required";
    public const string Pending = "pending";
    public const string Granted = "granted";
}

public static class UserStatuses
{
    public const string Pending = "pending";
    public const string PendingParentalConsent = "pending_parental_consent";
    public const string Active = "active";
    public const string Suspended = "suspended";
    public const string Deleted = "deleted";
}
